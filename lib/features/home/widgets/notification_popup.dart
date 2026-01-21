import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPopup extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const NotificationPopup({
    super.key,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed Background
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggle,
              child: Container(color: Colors.black.withValues(alpha: 0.05)),
            ),
          ),

        // Sliding Card
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          top: 100,
          right: isOpen ? 24 : -350,
          width: 280,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggle,
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationItem(
                    'Booking Confirmed',
                    'Your spot at Central Plaza is reserved.',
                    '2m ago',
                  ),
                  _buildNotificationItem(
                    'Promo Available',
                    'Get 20% off your next parking.',
                    '1h ago',
                  ),
                  _buildNotificationItem(
                    'Welcome to ParkWise',
                    'Find the best spots near you!',
                    '1d ago',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
