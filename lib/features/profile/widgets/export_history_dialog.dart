import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:parkwise/features/profile/services/booking_firestore_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Default range: Account creation -> Today
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
            colorScheme: ColorScheme.light(
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
      // 1. Fetch Data (Directly from stream for now, or could change service to get Future)
      // Since service returns Stream, we'll take the first snapshot.
      // Ideally service should have a 'getHistory(start, end)' method, but we can filter client side.
      final stream = _bookingService.getBookingsStream();
      final allItems = await stream.first;

      // 2. Filter
      final filteredItems = allItems.where((item) {
        return item.date.isAfter(
              _startDate!.subtract(const Duration(days: 1)),
            ) &&
            item.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      // 3. Generate PDF
      final pdf = pw.Document();
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'User';

      pdf.addPage(
        pw.Page(
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
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Parking History',
                        style: const pw.TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'User: $userName',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Date Range: ${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'Date',
                    'Spot',
                    'Time',
                    'Duration',
                    'Method',
                    'Amount',
                  ],
                  data: filteredItems.map((item) {
                    return [
                      DateFormat('dd MMM yy').format(item.date),
                      item.spotName,
                      DateFormat('hh:mm a').format(item.date),
                      item.duration,
                      item.paymentMethod,
                      'Rs. ${item.amount}',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                  ),
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    5: pw.Alignment.centerRight,
                  },
                ),
              ],
            );
          },
        ),
      );

      // 4. Share
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'parkwise_${userName.replaceAll(' ', '_')}_history.pdf',
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog on success? Or stay open.
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
