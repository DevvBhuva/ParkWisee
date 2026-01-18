import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/notifications/models/notification_model.dart';
import 'package:parkwise/features/notifications/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService _service = NotificationService();

    return Scaffold(
      backgroundColor: Colors.black, // Dark background as per design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _service.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.confirmation:
        icon = Icons.check_box;
        color = const Color(0xFF4ADE80); // Green
        break;
      case NotificationType.reminder:
        icon = Icons.alarm;
        color = const Color(0xFFF472B6); // Pink/Redish for timer
        break;
      case NotificationType.critical:
        icon = Icons.hourglass_bottom;
        color = const Color(0xFF60A5FA); // Blue/Orange for critical
        break;
      case NotificationType.expired:
        icon = Icons.remove_circle;
        color = const Color(0xFFF87171); // Red
        break;
      default:
        icon = Icons.info;
        color = Colors.white;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              _getHeaderText(notification.type),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Bullet Points
        _buildBulletPoint(
          'Title',
          notification.title,
          isTitle: true,
          tick: notification.type == NotificationType.confirmation,
        ),
        const SizedBox(height: 4),
        _buildBulletPoint('Body', notification.body),
      ],
    );
  }

  String _getHeaderText(NotificationType type) {
    switch (type) {
      case NotificationType.confirmation:
        return 'Booking confirmation';
      case NotificationType.reminder:
        return 'Parking start reminder';
      case NotificationType.critical:
        return 'Parking ending soon (critical)';
      case NotificationType.expired:
        return 'Parking expired';
      default:
        return 'Notification';
    }
  }

  Widget _buildBulletPoint(
    String label,
    String text, {
    bool isTitle = false,
    bool tick = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 12), // Indent bullet
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                  if (tick) ...[
                    const WidgetSpan(child: SizedBox(width: 4)),
                    const WidgetSpan(
                      child: Icon(
                        Icons.check_box,
                        color: Color(0xFF4ADE80),
                        size: 14,
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
