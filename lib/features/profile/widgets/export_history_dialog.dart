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
    _startDate = user?.metadata.creationTime ?? DateTime(2024);
    _endDate = _today;
  }

  Future<void> _pickDateRange() async {
    final user = FirebaseAuth.instance.currentUser;
    final firstDate = user?.metadata.creationTime ?? DateTime(2020);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: _today,
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
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
      // Remote
      List<Booking> remoteBookings = [];
      try {
        final snapshot = await _bookingService
            .getBookingsStream(user.uid)
            .first;
        remoteBookings = snapshot;
      } catch (e) {
        debugPrint('Remote fetch error: $e');
      }

      // Local
      final localBookings = await _localBookingService.getLocalBookings(
        user.uid,
      );

      // Merge (Remote overrides Local by ID)
      final Map<String, Booking> bookingMap = {};
      for (var b in localBookings) {
        bookingMap[b.id] = b;
      }
      for (var b in remoteBookings) {
        bookingMap[b.id] = b;
      }
      final allItems = bookingMap.values.toList();

      // Sort desc
      allItems.sort((a, b) => b.startTime.compareTo(a.startTime));

      // 2. Filter
      final filteredItems = allItems.where((item) {
        return item.startTime.isAfter(
              _startDate!.subtract(const Duration(days: 1)),
            ) &&
            item.startTime.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      if (filteredItems.isEmpty) {
        throw Exception('No bookings found in selected range');
      }

      // 3. Generate PDF
      final pdf = pw.Document();
      final userName = user.displayName ?? 'User';

      // Load font if needed, or use default
      final font = await PdfGoogleFonts.outfitRegular();
      final fontBold = await PdfGoogleFonts.outfitBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PARKWISE',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Parking History',
                        style: pw.TextStyle(font: font, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'User: $userName',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Text(
                  'Email: ${user.email ?? ""}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Text(
                  'Date Range: ${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  border: null,
                  headers: ['Date', 'Spot Name', 'Vehicle', 'Time', 'Price'],
                  data: filteredItems.map((item) {
                    final durationHours = item.endTime
                        .difference(item.startTime)
                        .inHours;
                    final durationMins =
                        item.endTime.difference(item.startTime).inMinutes % 60;
                    final durationStr = '${durationHours}h ${durationMins}m';

                    return [
                      DateFormat('dd MMM yy').format(item.startTime),
                      item.spotName,
                      item.vehicleNumber,
                      '${DateFormat('HH:mm').format(item.startTime)} ($durationStr)',
                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    font: fontBold,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  cellStyle: pw.TextStyle(font: font, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                  ),
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 0.5,
                      ),
                    ),
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerLeft,
                    4: pw.Alignment.centerRight,
                  },
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total Bookings: ${filteredItems.length}',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // 4. Share
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'parkwise_history_${DateFormat('yyyyMMdd').format(_today)}.pdf',
      );

      if (mounted) {
        // Success feedback?
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export Parking History',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Select Date Range',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isExporting)
              const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            else
              ElevatedButton(
                onPressed: _exportPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Export PDF',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (!_isExporting)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
