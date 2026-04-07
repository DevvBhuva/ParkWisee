import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'package:parkwise/features/parking/screens/ticket_screen.dart';

class BookingItemCard extends StatelessWidget {
  final Booking booking;

  const BookingItemCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpired = booking.endTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isExpired
          ? colorScheme.surfaceContainer.withValues(alpha: 0.5)
          : colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketScreen(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isExpired
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_parking,
                  color: isExpired ? colorScheme.onSurfaceVariant : colorScheme.secondary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.spotName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isExpired ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(booking.startTime),
                      style: GoogleFonts.outfit(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${booking.endTime.difference(booking.startTime).inHours} hours',
                      style: GoogleFonts.outfit(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\u20B9${booking.totalPrice.toStringAsFixed(0)} • ${booking.vehicleNumber}',
                      style: GoogleFonts.outfit(
                        color: isExpired ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
