import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'dart:io' show Platform;
import 'dart:ui'; // or package:flutter/material.dart

import 'dart:async'; // Added for Timer

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  // Track active bookings for "Live Activity" updates
  final List<Booking> _activeBookings = [];
  Timer? _progressTimer;

  LocalNotificationService._internal();

  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones(); // Initialize time zones
      // Set local location if possible, otherwise it defaults to UTC or system?
      // tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Optional: set if known
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Request permissions (Android 13+)
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final platform = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin
          >();
      if (platform != null) {
        await platform.requestNotificationsPermission();
      }
    }
  }

  /// Restore active bookings from persistent storage (e.g. Firestore)
  /// Called on app startup to resume "Live Activity" timers
  void restoreActiveBookings(List<Booking> bookings) {
    if (bookings.isEmpty) return;

    final now = DateTime.now();
    final active = bookings.where((b) => b.endTime.isAfter(now)).toList();

    if (active.isEmpty) return;

    _activeBookings.clear();
    _activeBookings.addAll(active);

    debugPrint(
      "Restored ${_activeBookings.length} active bookings for Live Timer.",
    );

    // Resume timer immediately
    _startProgressTimer();
  }

  /// Schedule all lifecycle notifications for a booking
  Future<void> scheduleBookingNotifications(Booking booking) async {
    // Immediate confirmation
    await showBookingConfirmation(booking);

    // Start Sticky Timer (Initial State)
    if (!_activeBookings.any((b) => b.id == booking.id)) {
      _activeBookings.add(booking);
    }

    // Start the timer loop if not running
    _startProgressTimer();

    // Show initial 0%
    await showParkingProgress(booking: booking, progress: 0, maxProgress: 100);

    // Scheduled reminders
    await _scheduleStartReminder(booking);
    await _scheduleEndReminder(booking);
    await _scheduleExpiryAlert(booking);
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_activeBookings.isEmpty) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      // Identify expired bookings to cancel their progress notification
      final expired = _activeBookings
          .where((b) => b.endTime.isBefore(now))
          .toList();
      for (var b in expired) {
        flutterLocalNotificationsPlugin.cancel(b.id.hashCode + 50);
      }
      _activeBookings.removeWhere((b) => b.endTime.isBefore(now));

      for (var booking in _activeBookings) {
        final totalDuration = booking.endTime
            .difference(booking.startTime)
            .inMinutes;
        final elapsed = now.difference(booking.startTime).inMinutes;

        // Clamp progress
        int progress = 0;
        if (totalDuration > 0) {
          progress = ((elapsed / totalDuration) * 100).clamp(0, 100).toInt();
        }

        await showParkingProgress(
          booking: booking,
          progress: progress,
          maxProgress: 100,
        );
      }
    });
  }

  Future<void> showBookingConfirmation(Booking booking) async {
    const androidDetails = fln.AndroidNotificationDetails(
      'booking_confirmation',
      'Booking Confirmations',
      channelDescription: 'Notifications for confirmed bookings',
      importance: fln.Importance.max,
      priority: fln.Priority.max,
    );
    const iosDetails = fln.DarwinNotificationDetails();
    const details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      booking.id.hashCode + 99, // Unique ID for confirmation
      'Booking Confirmed! ✅',
      'Your slot at ${booking.spotName} is reserved.',
      details,
      payload: 'booking_${booking.id}',
    );
  }

  /// Show a generic notification (e.g. from FCM)
  Future<void> showForegroundNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = fln.AndroidNotificationDetails(
      'fcm_foreground',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    const iosDetails = fln.DarwinNotificationDetails();
    const details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show a "Sticky" progress notification for active parking
  Future<void> showParkingProgress({
    required Booking booking,
    required int progress,
    required int maxProgress,
  }) async {
    final remainingMinutes = booking.endTime
        .difference(DateTime.now())
        .inMinutes;

    // Android: Use native progress bar
    final androidDetails = fln.AndroidNotificationDetails(
      'parking_timer',
      'Active Parking Timer',
      channelDescription: 'Ongoing notification for active parking',
      importance: fln.Importance.low, // Low importance to prevent popping up
      priority: fln.Priority.low,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true, // Specific for "Live Activity" feel (cannot dismiss)
      onlyAlertOnce: true,
      autoCancel: false,
      color: const Color(0xFF00C853),
    );

    const iosDetails = fln.DarwinNotificationDetails();

    final details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      booking.id.hashCode + 50, // Unique ID for timer
      'Parking Active • ${remainingMinutes}m remaining',
      'Vehicle: ${booking.vehicleNumber}',
      details,
      payload: 'booking_${booking.id}',
    );
  }

  Future<void> _scheduleStartReminder(Booking booking) async {
    // 15 minutes before start
    final scheduledTime = booking.startTime.subtract(
      const Duration(minutes: 15),
    );
    if (scheduledTime.isBefore(DateTime.now()))
      return; // Don't schedule in past

    await _scheduleNotification(
      id: booking.id.hashCode, // Unique ID derived from booking ID
      title: 'Parking Starts Soon',
      body: 'Your booking at ${booking.spotName} starts in 15 minutes.',
      scheduledDate: scheduledTime,
      payload: 'booking_${booking.id}',
    );
  }

  Future<void> _scheduleEndReminder(Booking booking) async {
    // 15 minutes before end
    final scheduledTime = booking.endTime.subtract(const Duration(minutes: 15));
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _scheduleNotification(
      id: booking.id.hashCode + 1, // Offset ID
      title: 'Parking Ending Soon',
      body:
          'Your slot at ${booking.spotName} expires in 15 minutes. Extend to avoid fines.',
      scheduledDate: scheduledTime,
      payload: 'booking_${booking.id}',
    );
  }

  Future<void> _scheduleExpiryAlert(Booking booking) async {
    // At exact end time
    if (booking.endTime.isBefore(DateTime.now())) return;

    await _scheduleNotification(
      id: booking.id.hashCode + 2, // Offset ID
      title: 'Parking Expired',
      body:
          'Your booking time has ended. Please vacate the slot or pay extra charges.',
      scheduledDate: booking.endTime,
      payload: 'booking_${booking.id}',
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
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'parking_reminders', // Channel ID
            'Parking Reminders', // Channel Name
            channelDescription: 'Reminders for parking start and end times',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
          ),
          iOS: const fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('Scheduled notification "$title" for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      // If permission error, try scheduling inexactly or notify user
      if (e.toString().contains('SecurityException')) {
        debugPrint('Exact alarm permission missing. Falling back or ignoring.');
      }
    }
  }

  Future<void> cancelNotifications(int bookingHashCode) async {
    await flutterLocalNotificationsPlugin.cancel(bookingHashCode);
    await flutterLocalNotificationsPlugin.cancel(bookingHashCode + 1);
    await flutterLocalNotificationsPlugin.cancel(bookingHashCode + 2);
    await flutterLocalNotificationsPlugin.cancel(
      bookingHashCode + 50,
    ); // Cancel timer
  }
}
