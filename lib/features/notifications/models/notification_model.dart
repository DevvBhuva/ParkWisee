import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { confirmation, reminder, critical, expired, info }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? relatedBookingId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedBookingId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'isRead': isRead,
      'relatedBookingId': relatedBookingId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: _parseType(map['type']),
      isRead: map['isRead'] ?? false,
      relatedBookingId: map['relatedBookingId'],
    );
  }

  static NotificationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'confirmation':
        return NotificationType.confirmation;
      case 'reminder':
        return NotificationType.reminder;
      case 'critical':
        return NotificationType.critical;
      case 'expired':
        return NotificationType.expired;
      default:
        return NotificationType.info;
    }
  }
}
