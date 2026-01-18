import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/notifications/models/notification_model.dart';

class NotificationPopup extends StatelessWidget {
  final List<NotificationModel> notifications;
  final VoidCallback onMarkAllRead;

  const NotificationPopup({
    super.key,
    required this.notifications,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      alignment: Alignment.topCenter, // Appear near top
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 24, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _buildNotificationItem(item);
                  },
                ),
              ),

            // Footer Button
            if (notifications.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  onMarkAllRead();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Mark all as read',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    IconData icon;
    Color color;

    switch (item.type) {
      case NotificationType.confirmation:
        icon = Icons.check_circle;
        color = const Color(0xFF4ADE80);
        break;
      case NotificationType.reminder:
        icon = Icons.alarm;
        color = const Color(0xFFF472B6);
        break;
      case NotificationType.critical:
        icon = Icons.hourglass_bottom;
        color = const Color(0xFF60A5FA);
        break;
      case NotificationType.expired:
        icon = Icons.remove_circle;
        color = const Color(0xFFF87171);
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (!item.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.body,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
