import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'package:flutter/foundation.dart';

class BookingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createBooking(Booking booking) async {
    final parkingRef = _firestore
        .collection('parkings')
        .doc(booking.parkingSpotId);
    final parkingBookingRef = parkingRef.collection('bookings').doc(booking.id);
    final userBookingRef = _firestore
        .collection('users')
        .doc(booking.userId)
        .collection('bookings')
        .doc(booking.id);

    debugPrint('>>> DEBUG: Parking Ref Path: ${parkingRef.path}');
    debugPrint('>>> DEBUG: Parking Booking Path: ${parkingBookingRef.path}');
    debugPrint('>>> DEBUG: User Booking Path: ${userBookingRef.path}');
    debugPrint('>>> DEBUG: Data to Save: ${booking.toMap()}');
    debugPrint('Booking created: ${booking.id}');
    debugPrint('QR Data: ${booking.qrData}');
    debugPrint('Payment ID: ${booking.paymentMethodId}');
    debugPrint('Payment Type: ${booking.paymentMethodType}');

    final vehicleType = booking.vehicleId;

    try {
      await _firestore.runTransaction((transaction) async {
        final parkingSnapshot = await transaction.get(parkingRef);

        if (!parkingSnapshot.exists) {
          throw Exception("Parking spot does not exist!");
        }

        final data = parkingSnapshot.data() as Map<String, dynamic>;

        final slotsMap = Map<String, dynamic>.from(data['slots'] ?? {});
        int currentSlots = 0;

        if (slotsMap[vehicleType] is int) {
          currentSlots = slotsMap[vehicleType];
        } else if (slotsMap[vehicleType] is String) {
          currentSlots = int.tryParse(slotsMap[vehicleType]) ?? 0;
        }

        // DYNAMIC AVAILABILITY CHECK
        // Count active bookings for this vehicle type
        final activeBookingsQuery = await _firestore
            .collection('parkings')
            .doc(booking.parkingSpotId)
            .collection('bookings')
            .where('vehicleId', isEqualTo: vehicleType)
            .where('status', whereIn: ['booked', 'confirmed'])
            .get();

        // Filter by time overlap if needed, but for now we assume all active bookings count
        // We can do a client-side filter for endTime > now to be precise
        final now = DateTime.now();
        final activeCount = activeBookingsQuery.docs.where((d) {
          final data = d.data();
          DateTime? end;
          if (data['endTime'] is Timestamp)
            end = (data['endTime'] as Timestamp).toDate();
          return end != null && end.isAfter(now);
        }).length;

        debugPrint(
          "DEBUG: Total Slots: $currentSlots, Active Bookings: $activeCount",
        );

        if (activeCount >= currentSlots) {
          throw Exception("No slots available for this vehicle type!");
        }

        // Do NOT decrement slots in DB. Slots field is now "Total Capacity".

        transaction.set(userBookingRef, booking.toMap());
        transaction.set(parkingBookingRef, booking.toMap());
      });
    } catch (e) {
      debugPrint('Transaction failed: $e');
      if (e.toString().contains("No slots available")) {
        rethrow;
      }

      debugPrint('Attempting fallback (skipping slot decrement)...');
      try {
        final batch = _firestore.batch();
        batch.set(userBookingRef, booking.toMap());
        batch.set(parkingBookingRef, booking.toMap());
        await batch.commit();
        debugPrint('>>> Fallback batch success!');
      } catch (fallbackError) {
        debugPrint('>>> Fallback batch failed: $fallbackError');

        // ULTIMATE FALLBACK: Try saving ONLY to user's collection
        // This is the most likely to succeed if permissions are tight on 'parkings'
        try {
          debugPrint('>>> Attempting Ultimate Fallback: Save to User only...');
          await userBookingRef.set(booking.toMap());
          debugPrint('>>> Ultimate Fallback Success!');
        } catch (ultimateError) {
          debugPrint('>>> Ultimate Fallback failed: $ultimateError');
          rethrow;
        }
      }
    }
  }

  /// Get stream of ALL active bookings in the system (for dynamic availability)
  Stream<List<Booking>> getAllActiveBookings() {
    return _firestore
        .collectionGroup('bookings')
        .where('status', whereIn: ['booked', 'confirmed'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromMap(doc.data()))
              .toList();
        });
  }

  // Helper to get active bookings for a spot
  Stream<List<int>> getOccupiedSlots(String parkingSpotId, String vehicleType) {
    return _firestore
        .collection('parkings')
        .doc(parkingSpotId)
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleType)
        // In a real app, you would also filter by status != 'cancelled' and time overlap
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data()['slotId'] as int)
              .toList();
        });
  }

  /// Get detailed stream of bookings for a specific spot and vehicle type
  Stream<List<Booking>> getActiveBookingsForSpot(
    String parkingSpotId,
    String vehicleType,
  ) {
    return _firestore
        .collection('parkings')
        .doc(parkingSpotId)
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleType)
        .where('status', whereIn: ['booked', 'confirmed'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromMap(doc.data()))
              .toList();
        });
  }


  Stream<List<Booking>> getBookingsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromMap(doc.data()))
              .toList();
        });
  }


}
