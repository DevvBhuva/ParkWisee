import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/home/widgets/parking_details_popup.dart';

import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/parking/services/parking_firestore_service.dart';
import 'package:parkwise/features/home/screens/profile_screen.dart';
import 'package:parkwise/features/parking/screens/bookings_screen.dart';
import 'package:parkwise/features/notifications/services/notification_service.dart';
import 'package:parkwise/features/notifications/models/notification_model.dart';
import 'package:parkwise/features/notifications/widgets/notification_popup.dart';
import 'package:parkwise/features/navigation/screens/navigation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';
import 'package:parkwise/features/parking/models/booking_model.dart'; // Added for Booking type

import 'package:parkwise/features/home/models/location_model.dart';
import 'package:parkwise/features/home/services/location_service.dart';
import 'package:parkwise/features/notifications/services/local_notification_service.dart'; // Added
import 'package:parkwise/features/home/widgets/location_header_button.dart';
import 'package:parkwise/features/home/widgets/city_selection_popup.dart';
import 'package:parkwise/features/home/widgets/area_selection_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedVehicleIndex = -1; // No vehicle selected by default
  final ParkingFirestoreService _parkingService = ParkingFirestoreService();
  final BookingFirestoreService _bookingService = BookingFirestoreService();

  Timer? _cleanupTimer; // Added

  // Location State
  final LocationService _locationService = LocationService();
  City? _selectedCity;
  Area? _selectedArea;

  @override
  void initState() {
    super.initState();
    _cleanupBookings();

    // Run global cleanup periodically (every 60 seconds) to make it "dynamic"
    _cleanupTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _runGlobalCleanup();
    });
  }

  Future<void> _cleanupBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Cleanup user's expired bookings
      await _bookingService.checkAndReleaseExpiredBookings(user.uid);

      // 1b. Global cleanup
      await _runGlobalCleanup();

      // 2. Restore active bookings for Live Notifications (Realtime Timer)
      final allBookingsStream = _bookingService.getBookingsStream(user.uid);
      final allBookings = await allBookingsStream.first; // Get current snapshot

      // Filter for active ones (confirmed and not end time passed)
      final now = DateTime.now();
      final active = allBookings
          .where(
            (b) =>
                (b.status == 'confirmed' || b.status == 'booked') &&
                b.endTime.isAfter(now),
          )
          .toList();

      if (active.isNotEmpty) {
        LocalNotificationService().restoreActiveBookings(active);
      }
    }
  }

  Future<void> _runGlobalCleanup() async {
    // Global cleanup for all parking spots (Client-side sync)
    // accessible to this user.
    try {
      final parkingsStream = _parkingService.getParkingSpots();
      final parkings = await parkingsStream.first;
      for (var spot in parkings) {
        await _bookingService.checkAndReleaseExpiredBookingsForParking(spot.id);
      }
      debugPrint("Global cleanup executed.");
    } catch (e) {
      debugPrint("Global cleanup failed: $e");
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  // Vehicle Categories
  final List<Map<String, dynamic>> _vehicleCategories = [
    {'name': 'Hatchback', 'image': 'assets/images/hatchback_icon.jpg'},
    {'name': 'SUV', 'image': 'assets/images/suv_icon.png'},
    {'name': 'Sedan', 'image': 'assets/images/sedan_icon.jpg'},
    {'name': 'EV', 'image': 'assets/images/ev_icon.jpg'},
    {'name': 'Bike', 'image': 'assets/images/bike_icon.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Light grey background
      body: Stack(
        children: [
          // Main Content
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeContent(),
              const BookingsScreen(),
              const NavigationScreen(),
              const ProfileScreen(),
            ],
          ),

          // Floating Bottom Navigation
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Search & Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location Button
              CompositedTransformTarget(
                link: _layerLink,
                child: LocationHeaderButton(
                  locationText: _selectedArea != null && _selectedCity != null
                      ? '${_selectedArea!.name}, ${_selectedCity!.name}'
                      : _selectedCity?.name ?? 'Select Location',
                  onTap: _showCitySelection,
                ),
              ),
              _buildHeaderButton(Icons.notifications_outlined),
            ],
          ),
          const SizedBox(height: 32),

          // "Choose Vehicle" Section
          Text(
            'Choose Vehicle',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A), // Dark text color
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling for vehicles if needed, or row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _vehicleCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildVehicleCard(
                    index,
                    category['name'],
                    category['image'],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // "Parking Spot" Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parking Spot',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: _showAllSpots,
                child: Text(
                  'See All',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(
                      0xFF4ADE80,
                    ), // Light Green - reference color
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Parking List
          StreamBuilder<List<ParkingSpot>>(
            stream: _parkingService.getParkingSpots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                // Return generic error, or empty list
                return const SizedBox.shrink();
              }

              // NEW: Listen to active bookings stream for dynamic availability
              return StreamBuilder<List<Booking>>(
                stream: _bookingService.getAllActiveBookings(),
                builder: (context, bookingSnapshot) {
                  // We continue even if bookings are loading (assume 0 active) or error
                  // Real-time updates will work when data arrives.
                  final activeBookings = bookingSnapshot.data ?? [];

                  // Calculate Dynamic Availability
                  // We create a NEW list of ParkingSpots with updated 'vehicles' map
                  final allParkings = _mergeAvailability(
                    snapshot.data ?? [],
                    activeBookings,
                  );

                  // Filter Parkings
                  List<ParkingSpot> filteredParkings = allParkings;
                  String? selectedVehicleTypeKey;

                  if (_selectedVehicleIndex != -1) {
                    final category = _vehicleCategories[_selectedVehicleIndex];
                    selectedVehicleTypeKey = (category['name'] as String)
                        .toLowerCase();

                    debugPrint(
                      "DEBUG: Filtering for Vehicle: $selectedVehicleTypeKey",
                    );

                    filteredParkings = allParkings.where((spot) {
                      final vData = spot.vehicles[selectedVehicleTypeKey];

                      if (vData == null) {
                        debugPrint(
                          "DEBUG: Hiding ${spot.name} - Vehicle '$selectedVehicleTypeKey' not supported.",
                        );
                        return false;
                      }
                      // Check DYNAMICALLY CALCULATED slots
                      if (vData.slots <= 0) {
                        debugPrint(
                          "DEBUG: Hiding ${spot.name} - No slots available (Total - Booked <= 0)",
                        );
                        return false;
                      }

                      return true;
                    }).toList();
                  }

                  // Filter by Area Keyword if an area is selected
                  if (_selectedArea != null) {
                    final areaKeyword = _normalizeText(_selectedArea!.name);
                    debugPrint(
                      "DEBUG: Selected Area: ${_selectedArea!.name} -> Keyword: '$areaKeyword'",
                    );

                    if (areaKeyword.isNotEmpty) {
                      filteredParkings = filteredParkings.where((spot) {
                        final parkingText = _normalizeText(
                          '${spot.name} ${spot.address}',
                        );
                        return parkingText.contains(areaKeyword);
                      }).toList();
                    }
                  }

                  final displayParkings = filteredParkings.take(3).toList();

                  if (displayParkings.isEmpty && _selectedVehicleIndex != -1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No parking spots found for ${_vehicleCategories[_selectedVehicleIndex]['name']}",
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: displayParkings.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return _buildParkingCard(
                        displayParkings[index],
                        selectedVehicleTypeKey,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAllSpots() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Other Parking Spots',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Filtered list for "See All"
              Expanded(
                child: StreamBuilder<List<ParkingSpot>>(
                  stream: _parkingService.getParkingSpots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var parkings = snapshot.data!;

                    // Apply SAME filters as Home Screen
                    if (_selectedVehicleIndex != -1) {
                      final category =
                          _vehicleCategories[_selectedVehicleIndex];
                      final selectedVehicleTypeKey =
                          (category['name'] as String).toLowerCase();
                      parkings = parkings.where((spot) {
                        final vData = spot.vehicles[selectedVehicleTypeKey];
                        return vData != null && vData.slots > 0;
                      }).toList();
                    }

                    if (_selectedArea != null) {
                      final areaKeyword = _normalizeText(_selectedArea!.name);
                      if (areaKeyword.isNotEmpty) {
                        parkings = parkings.where((spot) {
                          final parkingText = _normalizeText(
                            '${spot.name} ${spot.address}',
                          );
                          return parkingText.contains(areaKeyword);
                        }).toList();
                      }
                    }

                    // Filter out the first 3 that are shown on home screen based on the filtered list
                    final otherParkings = parkings.length > 3
                        ? parkings.skip(3).toList()
                        : <ParkingSpot>[];

                    if (otherParkings.isEmpty) {
                      return Center(
                        child: Text(
                          "No more spots available nearby",
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: otherParkings.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) =>
                          _buildParkingCard(otherParkings[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  final NotificationService _notificationService = NotificationService();

  Widget _buildHeaderButton(IconData icon) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getNotificationsStream(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => NotificationPopup(
                notifications: notifications,
                onMarkAllRead: () {
                  _notificationService.markAllAsRead();
                },
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.black87),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(int index, String name, String imagePath) {
    bool isSelected = _selectedVehicleIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedVehicleIndex == index) {
            _selectedVehicleIndex = -1; // Deselect if tapped again
          } else {
            _selectedVehicleIndex = index;
          }
        });
      },
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // User: "highlighting part in bottom nav should match the colour with see all" (Light Green)
              // User: "user should select the choose vehicle and the highlighiting part in the same colour as see all"
              color: isSelected ? const Color(0xFF4ADE80) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              // Ideally change icon color if background is green (to white/black?), but images are assets.
              // Assuming they look okay on green.
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard(ParkingSpot parking, [String? selectedVehicleType]) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ParkingDetailsPopup(
            parking: parking,
            initialVehicleType: selectedVehicleType,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.asset(
                'assets/images/parking_aerial.jpg', // Or parking.imageUrl if valid
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          parking.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Address
                  Text(
                    parking.address,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Rating and Open Status
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        parking.rating.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        color: Colors.grey.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      // Display Time from DB
                      Text(
                        '${parking.openTime} - ${parking.closeTime}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const Spacer(),
                      if (parking.isOpen)
                        Text(
                          'OPEN', // "if parking is open then write OPEN in green same as see all"
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4ADE80), // Light Green
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Facilities Row
                  if (parking.facilities.isNotEmpty) ...[
                    SizedBox(
                      height: 24,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: parking.facilities.split(',').map((f) {
                          final facility = f.trim();
                          if (facility.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                facility,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Vehicles Row (Icons)
                  if (parking.vehicles.isNotEmpty) ...[
                    Row(
                      children: parking.vehicles.entries
                          .where((e) => e.value.slots > 0)
                          .map((e) {
                            IconData icon;
                            switch (e.key.toLowerCase()) {
                              case 'bike':
                                icon = Icons.two_wheeler;
                                break;
                              case 'ev':
                                icon = Icons.electric_car;
                                break;
                              case 'suv':
                                icon = Icons.directions_car;
                                break;
                              case 'hatchback':
                                icon = Icons.directions_car_filled;
                                break;
                              default:
                                icon = Icons.local_taxi;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                icon,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding for pill shape
      decoration: BoxDecoration(
        color: Colors.white, // "bottom nav colour should be white along"
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ), // Adjusted shadow for white bg
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Even spacing
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.calendar_today_rounded, 'Booking'),
          _buildNavItem(2, Icons.near_me_outlined, 'Nav'),
          _buildNavItem(3, Icons.person_outline, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.all(12),
        decoration: isSelected
            ? const BoxDecoration(
                // "highlighting part in bottom nav should match the colour with see all" (Light Green)
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle,
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              // Icon color dark on white bg or green bg
              color: isSelected ? Colors.black : Colors.grey.shade400,
              size: 24,
            ),
            // Show text ONLY if selected (implied by "in highlighted paRT icon n text both will come")
            // and unselected usually just icons in this style.
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10, // Small text inside circle
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              // Small dot indicator as seen in image
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showOverlay(Widget child) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent dismissible background
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeOverlay,
              behavior: HitTestBehavior.translucent,
              // Dimmed background
              child: Container(color: Colors.black54),
            ),
          ),
          // Positioned Popup
          CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(0, 50), // Position below the button
            showWhenUnlinked: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 400,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showCitySelection() {
    _showOverlay(
      StreamBuilder<List<City>>(
        stream: _locationService.getCities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final cities = snapshot.data ?? [];
          if (cities.isEmpty) {
            return const Center(child: Text("No cities found"));
          }

          return CitySelectionPopup(
            cities: cities,
            onClose: _closeOverlay,
            onCitySelected: (city) {
              setState(() {
                _selectedCity = city;
                _selectedArea = null;
              });
              _closeOverlay();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAreaSelection(city);
              });
            },
          );
        },
      ),
    );
  }

  void _showAreaSelection(City city) {
    _showOverlay(
      StreamBuilder<List<Area>>(
        stream: _locationService.getAreas(city.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final areas = snapshot.data ?? [];
          // Note: Even if empty, we might want to show popup so user can see "No areas found"

          return AreaSelectionPopup(
            city: city,
            areas: areas,
            onClose: _closeOverlay,
            onAreaSelected: (area) {
              setState(() {
                _selectedArea = area;
              });
              _closeOverlay();
            },
          );
        },
      ),
    );
  }

  // Normalize text for keyword matching
  String _normalizeText(String text) {
    // 1. Lowercase
    String normalized = text.toLowerCase();

    // 2. Remove special characters (keep a-z, 0-9, and space)
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), '');

    // 3. Remove ignore words
    const ignoreWords = {
      'road',
      'street',
      'st',
      'avenue',
      'ave',
      'lane',
      'ln',
      'drive',
      'dr',
      'way',
      'boulevard',
      'blvd',
    };

    List<String> words = normalized.split(RegExp(r'\s+'));
    words.removeWhere((w) => ignoreWords.contains(w) || w.isEmpty);

    return words.join(' ');
  }

  // Merge static parking data (Total Slots) with active bookings to determine availability
  List<ParkingSpot> _mergeAvailability(
    List<ParkingSpot> parkings,
    List<Booking> bookings,
  ) {
    if (bookings.isEmpty) return parkings;

    final now = DateTime.now();

    return parkings.map((spot) {
      // 1. Find bookings for this spot
      final spotBookings = bookings
          .where(
            (b) =>
                b.parkingSpotId == spot.id &&
                (b.status == 'booked' || b.status == 'confirmed') &&
                b.endTime.isAfter(now),
          )
          .toList();

      // 2. Clone vehicles map to modify slots
      final newVehicles = Map<String, VehicleData>.from(spot.vehicles);

      for (var key in newVehicles.keys) {
        final total =
            newVehicles[key]!.slots; // Assumes DB 'slots' is Total Capacity
        final price = newVehicles[key]!.price;

        // Count usage
        final usage = spotBookings.where((b) => b.vehicleId == key).length;

        // Calculate Available
        final available = total - usage;

        // Update map
        newVehicles[key] = VehicleData(price: price, slots: available);

        debugPrint(
          "DEBUG: ${spot.name} [$key] -> Total: $total, Used: $usage, Avail: $available",
        );
      }

      // Return new ParkingSpot instance (manually copying fields since no copyWith)
      return ParkingSpot(
        id: spot.id,
        name: spot.name,
        address: spot.address,
        pricePerHour: spot.pricePerHour,
        rating: spot.rating,
        latitude: spot.latitude,
        longitude: spot.longitude,
        imageUrl: spot.imageUrl,
        totalSpots: spot.totalSpots,
        availableSpots: spot
            .availableSpots, // Kept as original, but 'vehicles' map has logic
        facilities: spot.facilities,
        vehicles: newVehicles,
        isOpen: spot.isOpen,
        reviewCount: spot.reviewCount,
        openTime: spot.openTime,
        closeTime: spot.closeTime,
      );
    }).toList();
  }
}
