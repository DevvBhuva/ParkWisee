import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'dart:io' show Platform;

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  LocalNotificationService._internal();

  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();
      // Optional: Set default location if needed, e.g.
      // tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final platform = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (platform != null) {
        await platform.requestNotificationsPermission();
      }
    } else if (Platform.isIOS) {
      final platform = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (platform != null) {
        await platform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
  }

  /// Schedule all notifications for a booking
  Future<void> scheduleBookingNotifications(Booking booking) async {
    // 1. Immediate Confirmation
    await showBookingConfirmedNotification(booking);

    // 2. Schedule Start Reminder (5 mins before)
    await scheduleSlotStartNotification(booking);

    // 3. Schedule End Reminder (5 mins before)
    await scheduleSlotEndNotification(booking);
  }

  Future<void> showBookingConfirmedNotification(Booking booking) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_confirmation',
      'Booking Confirmations',
      channelDescription: 'Notifications for confirmed bookings',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      booking.id.hashCode,
      'Booking Confirmed',
      'Booking confirmed for vehicle ${booking.vehicleNumber} at ${booking.spotName}.',
      details,
      payload: 'booking_${booking.id}',
    );
  }

  Future<void> scheduleSlotStartNotification(Booking booking) async {
    // 5 minutes before start
    final scheduledTime = booking.startTime.subtract(
      const Duration(minutes: 5),
    );

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint("Slot start notification time is in the past. Skipping.");
      return;
    }

    await _scheduleNotification(
      id: booking.id.hashCode + 1,
      title: 'Parking Starts Soon',
      body: 'Your parking slot will start in 5 minutes.',
      scheduledDate: scheduledTime,
      payload: 'booking_start_${booking.id}',
    );
  }

  Future<void> scheduleSlotEndNotification(Booking booking) async {
    // 5 minutes before end
    final scheduledTime = booking.endTime.subtract(const Duration(minutes: 5));

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint("Slot end notification time is in the past. Skipping.");
      return;
    }

    await _scheduleNotification(
      id: booking.id.hashCode + 2,
      title: 'Parking Ends Soon',
      body: 'Your parking slot will end in 5 minutes.',
      scheduledDate: scheduledTime,
      payload: 'booking_end_${booking.id}',
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      // Ensure local time zone is set, or fallback to UTC if needed.
      // For now, we assume initializeTimeZones() was called.
      // If tz.local is not available, this might throw.

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'parking_reminders',
            'Parking Reminders',
            channelDescription: 'Reminders for parking start and end times',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('Scheduled notification "$title" for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotifications(int bookingHashCode) async {
    await flutterLocalNotificationsPlugin.cancel(bookingHashCode);
    await flutterLocalNotificationsPlugin.cancel(bookingHashCode + 1);
    await flutterLocalNotificationsPlugin.cancel(bookingHashCode + 2);
  }
}
