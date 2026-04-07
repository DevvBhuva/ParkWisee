import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkwise/features/home/models/location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<City>> getCities() {
    return _firestore.collection('locations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Area>> getAreas(String cityId) {
    return _firestore
        .collection('locations')
        .doc(cityId)
        .collection('areas')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Area.fromMap(doc.data())).toList();
        });
  }

  /// Fetches all sub-areas across all cities in a single pass.
  /// Uses collectionGroup to query all 'areas' subcollections at once.
  Stream<List<Area>> getAllAreas() {
    return _firestore.collectionGroup('areas').snapshots().map((snapshot) {
      final areas =
          snapshot.docs.map((doc) => Area.fromMap(doc.data())).toList();
      areas.sort((a, b) => a.name.compareTo(b.name));
      return areas;
    });
  }
}
