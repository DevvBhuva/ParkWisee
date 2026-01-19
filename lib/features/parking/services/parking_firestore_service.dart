import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';

class ParkingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ParkingSpot>> getParkingSpots() {
    return _firestore.collection('parkings').snapshots().map((snapshot) {
      debugPrint("DEBUG: Snapshot received. Docs: ${snapshot.docs.length}");
      for (var doc in snapshot.docs) {
        debugPrint("DEBUG: Raw Data for ${doc.id}: ${doc.data()}");
      }
      return snapshot.docs.map((doc) {
        try {
          final spot = ParkingSpot.fromFirestore(doc);
          debugPrint(
            "DEBUG: Parsed Spot: ${spot.name}, Lat: ${spot.latitude}, Lng: ${spot.longitude}",
          );
          return spot;
        } catch (e, stack) {
          debugPrint("DEBUG: Error parsing ${doc.id}: $e");
          debugPrint(stack.toString());
          // Return a placeholder or rethrow to ensure we see the failure
          throw e;
        }
      }).toList();
    });
  }

  Future<List<ParkingSpot>> searchParkingSpots(String query) async {
    // Note: Firestore doesn't support native full-text search.
    // We'll fetch relevant documents and filter client-side or use a simple prefix match.
    // For this implementation, we'll try a prefix match on 'parking_name'.
    // Ensure you have a composite index if combining with other filters.

    try {
      final snapshot = await _firestore
          .collection('parkings')
          .where('parking_name', isGreaterThanOrEqualTo: query)
          .where('parking_name', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => ParkingSpot.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error searching firestore: $e");
      return [];
    }
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
