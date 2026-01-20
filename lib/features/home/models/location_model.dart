import 'package:cloud_firestore/cloud_firestore.dart';

class City {
  final String id;
  final String name;
  final List<Area> areas;

  City({required this.id, required this.name, required this.areas});

  factory City.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Areas might be in a subcollection now, so we just initialize an empty list here.
    // We will fetch them separately when the city is selected.
    return City(id: doc.id, name: data['name'] ?? 'Unknown City', areas: []);
  }
}

class Area {
  final String name;
  final double latitude;
  final double longitude;

  Area({required this.name, required this.latitude, required this.longitude});

  factory Area.fromMap(Map<String, dynamic> map) {
    // Safe parsing helper
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double lat = 0.0;
    double lng = 0.0;

    if (map['location'] is Map<String, dynamic>) {
      final locMap = map['location'] as Map<String, dynamic>;
      lat = parseDouble(locMap['latitude'] ?? locMap['lat']);
      lng = parseDouble(locMap['longitude'] ?? locMap['lng'] ?? locMap['long']);
    } else {
      lat = parseDouble(map['latitude'] ?? map['lat']);
      lng = parseDouble(map['longitude'] ?? map['long'] ?? map['lng']);
    }

    return Area(name: map['name'] ?? '', latitude: lat, longitude: lng);
  }
}
