import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleData {
  final double price;
  final int slots;

  VehicleData({required this.price, required this.slots});
}

class ParkingSpot {
  final String id;
  final String name;
  final String address;
  final double pricePerHour;
  final double rating;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final int totalSpots;
  final int availableSpots;
  final String facilities;
  final Map<String, VehicleData> vehicles;
  final bool isOpen;
  final int reviewCount;
  final String openTime;
  final String closeTime;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.totalSpots,
    required this.availableSpots,
    required this.facilities,
    required this.vehicles,
    this.isOpen = true,
    this.reviewCount = 0,
    this.openTime = '06:00 AM',
    this.closeTime = '11:00 PM',
  });

  factory ParkingSpot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>? ?? {};
    final pricesMap = data['prices'] as Map<String, dynamic>? ?? {};
    final slotsMap = data['slots'] as Map<String, dynamic>? ?? {};

    // Parse vehicles values
    Map<String, VehicleData> vehicles = {};

    // gather all vehicle types found in either map
    final allKeys = {...pricesMap.keys, ...slotsMap.keys};

    for (var key in allKeys) {
      // safe parsing for price
      double price = 0.0;
      final pVal = pricesMap[key];
      if (pVal is num) {
        price = pVal.toDouble();
      } else if (pVal is String) {
        price = double.tryParse(pVal) ?? 0.0;
      }

      // safe parsing for slots
      int slots = 0;
      final sVal = slotsMap[key];
      if (sVal is num) {
        slots = sVal.toInt();
      } else if (sVal is String) {
        slots = int.tryParse(sVal) ?? 0;
      }

      vehicles[key] = VehicleData(price: price, slots: slots);
    }

    // Determine base price (e.g. min price or hatchback)
    double basePrice = 20.0;
    if (vehicles.isNotEmpty) {
      // Prefer hatchback, then car, then first available
      if (vehicles.containsKey('hatchback')) {
        basePrice = vehicles['hatchback']!.price;
      } else if (vehicles.containsKey('car')) {
        basePrice = vehicles['car']!.price;
      } else {
        basePrice = vehicles.values.first.price;
      }
    }

    // safe parsing helper
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ParkingSpot(
      id: doc.id,
      name: data['parking_name'] ?? 'Unknown Parking',
      address: data['landmark'] ?? '',
      pricePerHour: basePrice,
      rating: parseDouble(data['rating'] ?? 4.2),
      latitude: parseDouble(
        data['latitude'] ??
            data['lat'] ??
            location['latitude'] ??
            location['lat'],
      ),
      longitude: parseDouble(
        data['longitude'] ??
            data['long'] ??
            data['lng'] ??
            location['longitude'] ??
            location['long'] ??
            location['lng'],
      ),
      imageUrl: data['imageUrl'] ?? 'assets/images/parking_aerial.jpg',
      totalSpots: data['totalSpots'] ?? 50,
      availableSpots: data['availableSpots'] ?? 20,
      facilities: data['facility'] ?? '',
      vehicles: vehicles,
      isOpen: data['isOpen'] ?? true,
      reviewCount: data['reviewCount'] ?? 100,
      openTime: data['openTime'] ?? '06:00 AM', // Parse from DB
      closeTime: data['closeTime'] ?? '11:00 PM', // Parse from DB
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'pricePerHour': pricePerHour,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'totalSpots': totalSpots,
      'availableSpots': availableSpots,
      'facility': facilities,
      'prices': vehicles.map(
        (k, v) => MapEntry(k, {'price': v.price, 'slots': v.slots}),
      ),
      'isOpen': isOpen,
      'reviewCount': reviewCount,
    };
  }
}
