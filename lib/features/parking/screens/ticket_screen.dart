import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
// import 'package:screenshot/screenshot.dart'; // Optional for download receipt
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // Would need this for actual download

class TicketScreen extends StatefulWidget {
  final Booking booking;

  const TicketScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  // final ScreenshotController _screenshotController = ScreenshotController();

  String _formatDate(DateTime dt) {
    return DateFormat('MMMM dd yyyy').format(dt);
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final s = DateFormat('h:mm a').format(start).toLowerCase();
    final e = DateFormat('h:mm a').format(end).toLowerCase();
    return '$s - $e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Receipt',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // RECEIPT CARD
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7), // Creamy/White background
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ticket Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Parking Name
                        Text(
                          widget.booking.spotName,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.booking.spotAddress,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Divider(height: 40),

                        // Date & Time (Bold)
                        _buildDetailRow(
                          'Date',
                          _formatDate(widget.booking.startTime),
                          isBold: true,
                        ),
                        _buildDetailRow(
                          'Time',
                          _formatTimeRange(
                            widget.booking.startTime,
                            widget.booking.endTime,
                          ),
                          isBold: true,
                        ),

                        // Price (Green)
                        _buildDetailRow(
                          'Price Paid',
                          '\u20B9${widget.booking.totalPrice.toStringAsFixed(0)}',
                          isBold: true,
                          color: Colors.green.shade700,
                        ),

                        const Divider(height: 30),

                        // Vehicle Info
                        _buildDetailRow(
                          'Vehicle Name',
                          widget.booking.vehicleId,
                        ),
                        _buildDetailRow(
                          'Vehicle Number',
                          widget.booking.vehicleNumber,
                          isBold: true,
                        ),

                        // Slot Info
                        _buildDetailRow(
                          'Slot Number',
                          'Slot P${widget.booking.slotId + 1}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const SizedBox(height: 20),

                  // QR Code Section
                  Center(
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.booking.qrData,
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan this QR code at entry/exit',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
