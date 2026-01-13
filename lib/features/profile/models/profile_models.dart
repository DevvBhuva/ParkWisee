import 'package:cloud_firestore/cloud_firestore.dart';
// Simple data models for the profile feature

class Vehicle {
  final String id;
  String name;
  String type; // e.g., Sedan, SUV, Bike
  String licensePlate;

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.licensePlate,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': type, 'licensePlate': licensePlate};
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
    );
  }
}

class PaymentMethod {
  final String id;
  final String category; // 'CARD' or 'UPI'
  final String type; // 'Visa', 'MasterCard' or 'GPay', 'PhonePe'
  final String maskedNumber; // For Card (Last 4 digits)
  final String expiryDate; // For Card
  final String? cardHolderName; // For Card
  final String? upiId; // For UPI

  PaymentMethod({
    required this.id,
    required this.category,
    required this.type,
    this.maskedNumber = '',
    this.expiryDate = '',
    this.cardHolderName,
    this.upiId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'type': type,
      'maskedNumber': maskedNumber,
      'expiryDate': expiryDate,
      'cardHolderName': cardHolderName,
      'upiId': upiId,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      category:
          map['category'] ??
          'CARD', // Default to CARD for backward compatibility
      type: map['type'] ?? '',
      maskedNumber: map['maskedNumber'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      cardHolderName: map['cardHolderName'],
      upiId: map['upiId'],
    );
  }
}

class SavedLocation {
  final String id;
  String name; // e.g., Home, Work
  String address;

  SavedLocation({required this.id, required this.name, required this.address});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'address': address};
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
    );
  }
}

class ParkingHistoryItem {
  final String id;
  final String spotName;
  final DateTime date;
  final String duration;
  final String vehicleType;
  final String paymentMethod; // 'Card' or 'UPI'
  final double amount;

  ParkingHistoryItem({
    required this.id,
    required this.spotName,
    required this.date,
    required this.duration,
    required this.vehicleType,
    required this.paymentMethod,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spotName': spotName,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'vehicleType': vehicleType,
      'paymentMethod': paymentMethod,
      'amount': amount,
    };
  }

  factory ParkingHistoryItem.fromMap(Map<String, dynamic> map) {
    return ParkingHistoryItem(
      id: map['id'] ?? '',
      spotName: map['spotName'] ?? 'Unknown Spot',
      date: (map['date'] as Timestamp).toDate(),
      duration: map['duration'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'Card',
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}
