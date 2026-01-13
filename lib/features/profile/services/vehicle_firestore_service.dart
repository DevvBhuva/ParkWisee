import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';

class VehicleFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Collection reference: users/{uid}/vehicles
  CollectionReference<Map<String, dynamic>> _getVehiclesCollection() {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(_userId).collection('vehicles');
  }

  // Stream of vehicles
  Stream<List<Vehicle>> getVehiclesStream() {
    if (_userId == null) return Stream.value([]);

    return _getVehiclesCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Ensure ID is from doc ID just in case, though we store it in map too
        final map = doc.data();
        map['id'] = doc.id;
        return Vehicle.fromMap(map);
      }).toList();
    });
  }

  // Add Vehicle
  Future<void> addVehicle(Vehicle vehicle) async {
    if (_userId == null) {
      debugPrint("Error: User Not Logged In. Cannot add vehicle.");
      throw Exception('User not logged in');
    }

    final docRef = _getVehiclesCollection().doc(); // Auto-ID
    // Update vehicle ID to match doc ID
    final newVehicle = Vehicle(
      id: docRef.id,
      name: vehicle.name,
      type: vehicle.type,
      licensePlate: vehicle.licensePlate,
    );

    try {
      debugPrint(
        "AddVehicle: Starting write to ${_getVehiclesCollection().path}/${docRef.id}",
      );
      await docRef.set(newVehicle.toMap());
      debugPrint("AddVehicle: Write successful!");
    } catch (e) {
      debugPrint("AddVehicle: Error writing to Firestore: $e");
      rethrow;
    }
  }

  // Update Vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    await _getVehiclesCollection().doc(vehicle.id).update(vehicle.toMap());
  }

  // Delete Vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    await _getVehiclesCollection().doc(vehicleId).delete();
  }
}
