import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String parkingSpotId;
  final String spotName;
  final String spotAddress;
  final int slotId;
  final String vehicleId; // e.g., 'car', 'bike' (Category Key)
  final String? vehicleModel; // e.g., 'Swift', 'Honda City'
  final String vehicleNumber; // e.g., 'GJ 01 AB 1234'
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status; // 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;
  final String qrData;
  final String? paymentMethodId;
  final String? paymentMethodType; // 'CARD', 'UPI', 'CASH'

  Booking({
    required this.id,
    required this.userId,
    required this.parkingSpotId,
    required this.spotName,
    required this.spotAddress,
    required this.slotId,
    required this.vehicleId,
    this.vehicleModel,
    required this.vehicleNumber,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.qrData,
    this.paymentMethodId,
    this.paymentMethodType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'parkingSpotId': parkingSpotId,
      'spotName': spotName,
      'spotAddress': spotAddress,
      'slotId': slotId,
      'vehicleId': vehicleId,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'qrData': qrData,
      'paymentMethodId': paymentMethodId,
      'paymentMethodType': paymentMethodType,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      parkingSpotId: map['parkingSpotId'] ?? '',
      spotName: map['spotName'] ?? '',
      spotAddress: map['spotAddress'] ?? '',
      slotId: map['slotId']?.toInt() ?? 0,
      vehicleId: map['vehicleId'] ?? '',
      vehicleModel: map['vehicleModel'],
      vehicleNumber: map['vehicleNumber'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: map['status'] ?? 'unknown',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      qrData: map['qrData'] ?? '',
      paymentMethodId: map['paymentMethodId'],
      paymentMethodType: map['paymentMethodType'],
    );
  }
}
