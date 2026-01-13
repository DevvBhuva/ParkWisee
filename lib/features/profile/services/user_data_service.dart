import 'dart:async';
import 'package:parkwise/features/profile/models/profile_models.dart';

class UserDataService {
  // Singleton pattern
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  // Mock Data
  final List<Vehicle> _vehicles = [
    Vehicle(id: '1', name: 'My Tesla', type: 'EV', licensePlate: 'ABC-1234'),
    Vehicle(id: '2', name: 'Family SUV', type: 'SUV', licensePlate: 'XYZ-9876'),
  ];

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: "1",
      category: 'CARD',
      type: "Visa",
      maskedNumber: "4242",
      expiryDate: "12/24",
    ),
    PaymentMethod(
      id: "2",
      category: 'CARD',
      type: "MasterCard",
      maskedNumber: "5555",
      expiryDate: "11/25",
    ),
  ];

  final List<SavedLocation> _savedLocations = [
    SavedLocation(id: '1', name: 'Home', address: '123 Main St, New York, NY'),
    SavedLocation(
      id: '2',
      name: 'Work',
      address: '456 Tech Park, San Francisco, CA',
    ),
  ];

  // Streams to notify UI of changes (simple state management)
  final _vehicleController = StreamController<List<Vehicle>>.broadcast();
  final _paymentController = StreamController<List<PaymentMethod>>.broadcast();
  final _locationController = StreamController<List<SavedLocation>>.broadcast();

  Stream<List<Vehicle>> get vehiclesStream => _vehicleController.stream;
  Stream<List<PaymentMethod>> get paymentsStream => _paymentController.stream;
  Stream<List<SavedLocation>> get locationsStream => _locationController.stream;

  // --- Vehicles ---
  List<Vehicle> getVehicles() => List.unmodifiable(_vehicles);

  void addVehicle(Vehicle vehicle) {
    _vehicles.add(vehicle);
    _vehicleController.add(_vehicles);
  }

  void updateVehicle(String id, String name, String type, String licensePlate) {
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index != -1) {
      _vehicles[index].name = name;
      _vehicles[index].type = type;
      _vehicles[index].licensePlate = licensePlate;
      _vehicleController.add(_vehicles);
    }
  }

  void deleteVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id);
    _vehicleController.add(_vehicles);
  }

  // --- Payment Methods ---
  List<PaymentMethod> getPaymentMethods() => List.unmodifiable(_paymentMethods);

  void addPaymentMethod(PaymentMethod method) {
    _paymentMethods.add(method);
    _paymentController.add(_paymentMethods);
  }

  void updatePaymentMethod(PaymentMethod method) {
    final index = _paymentMethods.indexWhere((p) => p.id == method.id);
    if (index != -1) {
      _paymentMethods[index] = method;
      _paymentController.add(_paymentMethods);
    }
  }

  void deletePaymentMethod(String id) {
    _paymentMethods.removeWhere((p) => p.id == id);
    _paymentController.add(_paymentMethods);
  }

  // --- Saved Locations ---
  List<SavedLocation> getSavedLocations() => List.unmodifiable(_savedLocations);

  void addSavedLocation(SavedLocation location) {
    _savedLocations.add(location);
    _locationController.add(_savedLocations);
  }

  void updateSavedLocation(String id, String name, String address) {
    final index = _savedLocations.indexWhere((l) => l.id == id);
    if (index != -1) {
      _savedLocations[index].name = name;
      _savedLocations[index].address = address;
      _locationController.add(_savedLocations);
    }
  }

  void deleteSavedLocation(String id) {
    _savedLocations.removeWhere((l) => l.id == id);
    _locationController.add(_savedLocations);
  }
}
