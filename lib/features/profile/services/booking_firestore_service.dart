import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';

class BookingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Collection Reference
  CollectionReference<Map<String, dynamic>> get _bookingsRef {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(_userId).collection('bookings');
  }

  // Add Booking (For simulation/testing)
  Future<void> addBooking(ParkingHistoryItem item) async {
    await _bookingsRef.add(item.toMap());
  }

  // Get Bookings Stream
  Stream<List<ParkingHistoryItem>> getBookingsStream() {
    if (_userId == null) return Stream.value([]);

    return _bookingsRef.orderBy('date', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ParkingHistoryItem.fromMap(data);
      }).toList();
    });
  }
}
