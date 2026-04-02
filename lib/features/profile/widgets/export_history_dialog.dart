import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';
import 'package:parkwise/features/parking/services/local_booking_service.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';

class ExportHistoryDialog extends StatefulWidget {
  const ExportHistoryDialog({super.key});

  @override
  State<ExportHistoryDialog> createState() => _ExportHistoryDialogState();
}

class _ExportHistoryDialogState extends State<ExportHistoryDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  final DateTime _today = DateTime.now();
  bool _isExporting = false;
  final BookingFirestoreService _bookingService = BookingFirestoreService();
  final LocalBookingService _localBookingService = LocalBookingService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    // Set default range to last 30 days or creation time
    _endDate = _today;
    _startDate = _today.subtract(const Duration(days: 30));
    final creationTime = user?.metadata.creationTime;
    if (creationTime != null && _startDate!.isBefore(creationTime)) {
      _startDate = creationTime;
    }
  }

  Future<void> _pickDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final firstDate = user?.metadata.creationTime ?? DateTime(2020);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: _today,
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    surface: Color(0xFF1A1A1A),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Fetch Data (Merge Local & Remote)
      List<Booking> remoteBookings = [];
      try {
        final snapshot = await _bookingService
            .getBookingsStream(user.uid)
            .first;
        remoteBookings = snapshot;
      } catch (e) {
        debugPrint('Remote fetch error: $e');
      }

      final localBookings = await _localBookingService.getLocalBookings(
        user.uid,
      );

      final Map<String, Booking> bookingMap = {};
      for (var b in localBookings) {
        bookingMap[b.id] = b;
      }
      for (var b in remoteBookings) {
        bookingMap[b.id] = b;
      }
      final allItems = bookingMap.values.toList();
      allItems.sort((a, b) => b.startTime.compareTo(a.startTime));

      // 2. Filter
      final filteredItems = allItems.where((item) {
        return item.startTime.isAfter(
              _startDate!.subtract(const Duration(seconds: 1)),
            ) &&
            item.startTime.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      if (filteredItems.isEmpty) {
        throw Exception('No bookings found in selected range');
      }

      // 3. Generate PDF
      final pdf = pw.Document();
      final userName = user.displayName ?? 'User';

      final font = await PdfGoogleFonts.outfitRegular();
      final fontBold = await PdfGoogleFonts.outfitBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PARKWISE',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        'Premium Parking Solutions',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PARKING HISTORY',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          color: PdfColor.fromHex('#2196F3'),
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd MMM yyyy').format(DateTime.now()),
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),
            ],
          ),
          footer: (pw.Context context) => pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated via Parkwise App',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          build: (pw.Context context) => [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Report For:',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        userName,
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.Text(
                        user.email ?? user.phoneNumber ?? '',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date Range:',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.TableHelper.fromTextArray(
              context: context,
              border: null,
              headerStyle: pw.TextStyle(
                font: fontBold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              headers: ['DATE', 'SPOT NAME', 'VEHICLE', 'DURATION', 'AMOUNT'],
              data: filteredItems.map((item) {
                final durationHours = item.endTime
                    .difference(item.startTime)
                    .inHours;
                final durationMins =
                    item.endTime.difference(item.startTime).inMinutes % 60;
                final durationStr = '${durationHours}h ${durationMins}m';

                return [
                  DateFormat('dd MMM yyyy').format(item.startTime),
                  item.spotName,
                  item.vehicleNumber,
                  durationStr,
                  'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                ];
              }).toList(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Total Bookings:',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        '${filteredItems.length}',
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Total Amount Paid:',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'Rs. ${filteredItems.fold(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          color: PdfColor.fromHex('#4CAF50'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // 4. Share
      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'Parkwise_History_${DateFormat('yyyyMMdd').format(_today)}.pdf',
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: backgroundColor,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)],
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Export History',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: subtitleColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Select date range for history report',
              style: GoogleFonts.outfit(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar_rounded,
                      size: 18,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isExporting)
              Column(
                children: [
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Generating PDF...',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: subtitleColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _exportPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'EXPORT PDF',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
