import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';

class LocalBookingService {
  static const String _storageKey = 'local_bookings';
  static final _updateController = StreamController<void>.broadcast();

  Stream<void> get onBookingUpdated => _updateController.stream;

  Future<void> saveBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsJson = prefs.getStringList(_storageKey) ?? [];

    final map = booking.toMap();
    // Overwrite timestamps with ISO strings for simple JSON storage
    map['startTime'] = booking.startTime.toIso8601String();
    map['endTime'] = booking.endTime.toIso8601String();
    map['createdAt'] = booking.createdAt.toIso8601String();

    bookingsJson.add(jsonEncode(map));
    await prefs.setStringList(_storageKey, bookingsJson);
    _updateController.add(null);
  }

  Future<List<Booking>> getLocalBookings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsJson = prefs.getStringList(_storageKey) ?? [];

    return bookingsJson
        .map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;

          return Booking(
            id: map['id'],
            userId: map['userId'],
            parkingSpotId: map['parkingSpotId'],
            spotName: map['spotName'],
            spotAddress: map['spotAddress'],
            slotId: map['slotId'],
            vehicleId: map['vehicleId'],
            vehicleNumber: map['vehicleNumber'],
            startTime: DateTime.parse(map['startTime']),
            endTime: DateTime.parse(map['endTime']),
            totalPrice: (map['totalPrice'] as num).toDouble(),
            status: map['status'],
            createdAt: DateTime.parse(map['createdAt']),
            qrData: map['qrData'],
            paymentMethodId: map['paymentMethodId'],
            paymentMethodType: map['paymentMethodType'],
          );
        })
        .where((b) => b.userId == userId)
        .toList();
  }
}
