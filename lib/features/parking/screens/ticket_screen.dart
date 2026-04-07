import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
// import 'package:screenshot/screenshot.dart'; // Optional for download receipt

// import 'package:image_gallery_saver/image_gallery_saver.dart'; // Would need this for actual download

class TicketScreen extends StatefulWidget {
  final Booking booking;

  const TicketScreen({super.key, required this.booking});

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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      appBar: AppBar(
        title: Text(
          'Receipt',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
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
                color: Theme.of(context).colorScheme.surface, // Creamy/White background
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.booking.spotAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.secondary,
                        ),

                        const Divider(height: 30),

                        // Vehicle Info
                        _buildDetailRow(
                          'Vehicle Name',
                          widget.booking.vehicleModel ??
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: DashedLinePainter(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // QR Code Section
                  Center(
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.booking.qrData,
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan this QR code at entry/exit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
