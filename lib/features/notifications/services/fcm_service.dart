import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:parkwise/features/notifications/services/local_notification_service.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // Note: LocalNotificationService might need re-initialization here if used,
  // but usually background handling is for data processing or simple logging if not strictly displaying UI.
  // Standard FCM notification/notification messages are handled by system tray automatically in background.
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Background Handler Registration
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );

        // Show local notification for foreground messages
        await _localNotificationService.showForegroundNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // 4. Token Management
    await _printToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token Refreshed: $newToken");
      // TODO: Send to backend
    });
  }

  Future<void> _printToken() async {
    String? token = await _firebaseMessaging.getToken();
    debugPrint("---------------------------------------");
    debugPrint("FCM Registration Token: $token");
    debugPrint("---------------------------------------");
  }
}
