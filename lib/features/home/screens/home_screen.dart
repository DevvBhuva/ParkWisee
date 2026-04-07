import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/parking/services/parking_firestore_service.dart';
import 'package:parkwise/features/profile/screens/profile_screen.dart';
import 'package:parkwise/features/parking/screens/bookings_screen.dart';
import 'package:parkwise/features/notifications/services/notification_service.dart';
import 'package:parkwise/features/notifications/models/notification_model.dart';
import 'package:parkwise/features/notifications/widgets/notification_popup.dart';
import 'package:parkwise/features/navigation/screens/navigation_screen.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';
import 'package:parkwise/features/parking/widgets/parking_spot_card.dart';
import 'package:parkwise/features/home/widgets/vehicle_category_card.dart';
import 'package:parkwise/core/widgets/section_header.dart';
import 'package:parkwise/core/widgets/page_animations.dart';
import 'package:parkwise/core/widgets/tap_animation.dart';

import 'package:parkwise/features/parking/models/booking_model.dart'; // Added for Booking type

import 'package:parkwise/features/home/models/location_model.dart';
import 'package:parkwise/features/home/widgets/location_header_button.dart';
import 'package:parkwise/features/home/widgets/sub_area_bottom_sheet.dart';

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

  // Location State
  Area? _selectedArea;

  @override
  void initState() {
    super.initState();
  }




  @override
  void dispose() {
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Search & Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location Button
              LocationHeaderButton(
                locationText: _selectedArea?.name ?? 'Select Area',
                onTap: _showAreaBottomSheet,
              ),
              _buildHeaderButton(Icons.notifications_outlined),
            ],
          ),
          const SizedBox(height: 32),

          // "Choose Vehicle" Section
          SectionHeader(title: 'Choose Vehicle'),
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
                  child: VehicleCategoryCard(
                    name: category['name'],
                    imagePath: category['image'],
                    isSelected: _selectedVehicleIndex == index,
                    onTap: () {
                      setState(() {
                        if (_selectedVehicleIndex == index) {
                          _selectedVehicleIndex = -1;
                        } else {
                          _selectedVehicleIndex = index;
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // "Parking Spot" Section
          SectionHeader(
            title: 'Parking Spot',
            actionText: 'See All',
            onActionTap: _showAllSpots,
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
                return const SizedBox.shrink();
              }

              return StreamBuilder<List<Booking>>(
                stream: _bookingService.getAllActiveBookings(),
                builder: (context, bookingSnapshot) {
                  final activeBookings = bookingSnapshot.data ?? [];
                  final allParkings = _mergeAvailability(
                    snapshot.data ?? [],
                    activeBookings,
                  );

                  List<ParkingSpot> filteredParkings = allParkings;
                  String? selectedVehicleTypeKey;

                  if (_selectedVehicleIndex != -1) {
                    final category = _vehicleCategories[_selectedVehicleIndex];
                    selectedVehicleTypeKey = (category['name'] as String).toLowerCase();
                    filteredParkings = allParkings.where((spot) {
                      final vData = spot.vehicles[selectedVehicleTypeKey];
                      return vData != null && vData.slots > 0;
                    }).toList();
                  }

                  if (_selectedArea != null) {
                    final areaKeyword = _normalizeText(_selectedArea!.name);
                    if (areaKeyword.isNotEmpty) {
                      filteredParkings = filteredParkings.where((spot) {
                        final parkingText = _normalizeText('${spot.name} ${spot.address}');
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
                          style: GoogleFonts.outfit(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: displayParkings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(displayParkings[index].id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: ParkingSpotCard(
                          parking: displayParkings[index],
                          selectedVehicleType: selectedVehicleTypeKey,
                        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
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
                  color: colorScheme.outlineVariant,
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
                    color: colorScheme.onSurface,
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

                    if (_selectedVehicleIndex != -1) {
                      final category = _vehicleCategories[_selectedVehicleIndex];
                      final selectedVehicleTypeKey = (category['name'] as String).toLowerCase();
                      parkings = parkings.where((spot) {
                        final vData = spot.vehicles[selectedVehicleTypeKey];
                        return vData != null && vData.slots > 0;
                      }).toList();
                    }

                    if (_selectedArea != null) {
                      final areaKeyword = _normalizeText(_selectedArea!.name);
                      if (areaKeyword.isNotEmpty) {
                        parkings = parkings.where((spot) {
                          final parkingText = _normalizeText('${spot.name} ${spot.address}');
                          return parkingText.contains(areaKeyword);
                        }).toList();
                      }
                    }

                    final otherParkings = parkings.length > 3 ? parkings.skip(3).toList() : <ParkingSpot>[];

                    if (otherParkings.isEmpty) {
                      return Center(
                        child: Text(
                          "No more spots available nearby",
                          style: GoogleFonts.outfit(color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: otherParkings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 20),
                      itemBuilder: (context, index) => ParkingSpotCard(parking: otherParkings[index]),
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
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getNotificationsStream(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return TapAnimation(
          onTap: () {
            showAnimatedDialog(
              context: context,
              child: NotificationPopup(
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
                  color: colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outline),
                  boxShadow: Theme.of(context).brightness == Brightness.light 
                    ? [
                        BoxShadow(
                          color: colorScheme.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                ),
                child: Icon(icon, color: colorScheme.onSurface),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingBottomNav() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: colorScheme.outline),
        boxShadow: Theme.of(context).brightness == Brightness.light 
          ? [
              BoxShadow(
                color: colorScheme.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    final colorScheme = Theme.of(context).colorScheme;
    final bool isSelected = _selectedIndex == index;

    return TapAnimation(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
            : const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Opens the sub-area selector as a modern bottom sheet.
  Future<void> _showAreaBottomSheet() async {
    final selected = await showSubAreaBottomSheet(context);
    if (selected != null && mounted) {
      setState(() {
        _selectedArea = selected;
      });
    }
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

  List<ParkingSpot> _mergeAvailability(
    List<ParkingSpot> parkings,
    List<Booking> bookings,
  ) {
    if (parkings.isEmpty) return parkings;

    final now = DateTime.now();

    // 1. Group bookings by parkingSpotId for O(1) lookup
    final Map<String, List<Booking>> spotBookingsMap = {};
    for (var b in bookings) {
      if ((b.status == 'booked' || b.status == 'confirmed') &&
          b.endTime.isAfter(now)) {
        spotBookingsMap.putIfAbsent(b.parkingSpotId, () => []).add(b);
      }
    }

    // 2. Efficiently merge availability
    return parkings.map((spot) {
      final spotBookings = spotBookingsMap[spot.id] ?? [];
      if (spotBookings.isEmpty) return spot;

      final newVehicles = Map<String, VehicleData>.from(spot.vehicles);

      for (var key in newVehicles.keys) {
        final total = newVehicles[key]!.slots;
        final usage = spotBookings.where((b) => b.vehicleId == key).length;
        final available = total - usage;

        newVehicles[key] = VehicleData(
          price: newVehicles[key]!.price,
          slots: available,
        );
      }

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
        availableSpots: spot.availableSpots,
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
