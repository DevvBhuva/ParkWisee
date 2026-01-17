import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';

class ParkingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ParkingSpot>> getParkingSpots() {
    return _firestore.collection('parkings').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingSpot.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addParkingSpot(ParkingSpot spot) async {
    await _firestore.collection('parkings').add(spot.toMap());
  }

  Future<void> batchAddParkingSpots(List<ParkingSpot> spots) async {
    final batch = _firestore.batch();
    for (var spot in spots) {
      final docRef = _firestore.collection('parkings').doc();
      batch.set(docRef, spot.toMap());
    }
    await batch.commit();
  }
}
