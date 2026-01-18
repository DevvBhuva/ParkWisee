import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/notifications/models/notification_model.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BookingFirestoreService _bookingService = BookingFirestoreService();

  // Create a persistent notification in Firestore
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? relatedBookingId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc();

    final notification = NotificationModel(
      id: docRef.id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      relatedBookingId: relatedBookingId,
    );

    await docRef.set(notification.toMap());
  }

  // Get stream of ALL notifications (Persistent + Generated Reminders)
  Stream<List<NotificationModel>> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // 1. Stream Persistent Notifications
    final persistentStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList(),
        );

    // 2. Stream Bookings for Dynamic Generation
    final bookingsStream = _bookingService.getBookingsStream(user.uid);

    // 3. Combine
    return StreamCombineLatest.combine2(persistentStream, bookingsStream, (
      List<NotificationModel> persistent,
      List<Booking> bookings,
    ) {
      final generated = _generateSmartNotifications(bookings);
      // Merge and sort
      final all = [...persistent, ...generated];
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return all;
    });
  }

  // Client-side logic to generate reminders based on booking state
  List<NotificationModel> _generateSmartNotifications(List<Booking> bookings) {
    final List<NotificationModel> generated = [];
    final now = DateTime.now();

    for (var booking in bookings) {
      // 1. Parking Starts Soon (15 min before)
      final timeToStart = booking.startTime.difference(now).inMinutes;
      if (timeToStart > 0 && timeToStart <= 15) {
        generated.add(
          NotificationModel(
            id: 'reminder_start_${booking.id}',
            title: 'Parking Starts Soon',
            body:
                'Your parking at ${booking.spotName} begins in $timeToStart minutes. Navigate now.',
            timestamp: now, // Show at top
            type: NotificationType.reminder,
            relatedBookingId: booking.id,
          ),
        );
      }

      // 2. Parking Ending Soon (10 min before)
      if (booking.status == 'confirmed') {
        final timeToEnd = booking.endTime.difference(now).inMinutes;
        if (timeToEnd > 0 && timeToEnd <= 10) {
          generated.add(
            NotificationModel(
              id: 'reminder_end_${booking.id}',
              title: 'Parking Ending in $timeToEnd Minutes',
              body: 'Extend your parking to avoid fines.',
              timestamp: now,
              type: NotificationType.critical,
              relatedBookingId: booking.id,
            ),
          );
        }
      }

      // 3. Parking Expired (Just now)
      if (booking.endTime.isBefore(now) &&
          booking.endTime.isAfter(now.subtract(const Duration(hours: 1)))) {
        // Only show "Expired" alert if it happened in the last hour to avoid cluttering old history
        generated.add(
          NotificationModel(
            id: 'expired_${booking.id}',
            title: 'Parking Time Expired',
            body: 'Your booking has ended. Extra charges may apply.',
            timestamp: booking.endTime,
            type: NotificationType.expired,
            relatedBookingId: booking.id,
          ),
        );
      }
    }
    return generated;
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}

// Simple StreamCombiner
class StreamCombineLatest {
  static Stream<R> combine2<A, B, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    R Function(A a, B b) combiner,
  ) {
    return Stream<R>.multi((controller) {
      A? a;
      B? b;
      bool hasA = false;
      bool hasB = false;

      StreamSubscription<A>? subA;
      StreamSubscription<B>? subB;

      void update() {
        if (hasA && hasB) {
          controller.add(combiner(a as A, b as B));
        }
      }

      subA = streamA.listen(
        (data) {
          a = data;
          hasA = true;
          update();
        },
        onError: controller.addError,
        onDone: () {
          // Keep alive until both done? Or close? usually close when either closes if strict
        },
      );

      subB = streamB.listen(
        (data) {
          b = data;
          hasB = true;
          update();
        },
        onError: controller.addError,
        onDone: () {},
      );

      controller.onCancel = () async {
        await subA?.cancel();
        await subB?.cancel();
      };
    });
  }
}
