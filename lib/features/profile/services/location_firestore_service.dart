import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';

class LocationFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _getCollection() {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(_userId).collection('locations');
  }

  Stream<List<SavedLocation>> getLocationsStream() {
    if (_userId == null) return Stream.value([]);

    return _getCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id;
        return SavedLocation.fromMap(map);
      }).toList();
    });
  }

  Future<void> addLocation(SavedLocation location) async {
    if (_userId == null) return;
    try {
      final docRef = _getCollection().doc();
      final newItem = SavedLocation(
        id: docRef.id,
        name: location.name,
        address: location.address,
      );
      await docRef.set(newItem.toMap());
      debugPrint("Location added: ${docRef.id}");
    } catch (e) {
      debugPrint("Error adding location: $e");
      rethrow;
    }
  }

  Future<void> updateLocation(SavedLocation location) async {
    try {
      await _getCollection().doc(location.id).update(location.toMap());
    } catch (e) {
      debugPrint("Error updating location: $e");
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _getCollection().doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting location: $e");
    }
  }
}
