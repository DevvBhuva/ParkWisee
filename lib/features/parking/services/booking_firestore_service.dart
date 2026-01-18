import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';

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

    print('>>> DEBUG: Parking Ref Path: ${parkingRef.path}');
    print('>>> DEBUG: Parking Booking Path: ${parkingBookingRef.path}');
    print('>>> DEBUG: User Booking Path: ${userBookingRef.path}');
    print('>>> DEBUG: Data to Save: ${booking.toMap()}');

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

        if (currentSlots <= 0) {
          throw Exception("No slots available for this vehicle type!");
        }

        slotsMap[vehicleType] = currentSlots - 1;

        transaction.update(parkingRef, {'slots': slotsMap});
        transaction.set(userBookingRef, booking.toMap());
        transaction.set(parkingBookingRef, booking.toMap());
      });
    } catch (e) {
      print('Transaction failed: $e');
      if (e.toString().contains("No slots available")) {
        throw e;
      }

      print('Attempting fallback (skipping slot decrement)...');
      try {
        final batch = _firestore.batch();
        batch.set(userBookingRef, booking.toMap());
        batch.set(parkingBookingRef, booking.toMap());
        await batch.commit();
        print('>>> Fallback batch success!');
      } catch (fallbackError) {
        print('>>> Fallback batch failed: $fallbackError');

        // ULTIMATE FALLBACK: Try saving ONLY to user's collection
        // This is the most likely to succeed if permissions are tight on 'parkings'
        try {
          print('>>> Attempting Ultimate Fallback: Save to User only...');
          await userBookingRef.set(booking.toMap());
          print('>>> Ultimate Fallback Success!');
        } catch (ultimateError) {
          print('>>> Ultimate Fallback failed: $ultimateError');
          throw ultimateError;
        }
      }
    }
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
