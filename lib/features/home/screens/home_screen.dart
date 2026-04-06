import 'package:flutter/material.dart';
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
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';

import 'package:parkwise/features/parking/models/booking_model.dart'; // Added for Booking type

import 'package:parkwise/features/home/models/location_model.dart';
import 'package:parkwise/features/home/services/location_service.dart';
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

  // Location State

  final LocationService _locationService = LocationService();
  City? _selectedCity;
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
              color: colorScheme.onSurface,
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
                  color: colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: _showAllSpots,
                child: Text(
                  'See All',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
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
                      itemBuilder: (context, index) => _buildParkingCard(otherParkings[index]),
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

  Widget _buildVehicleCard(int index, String name, String imagePath) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isSelected = _selectedVehicleIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedVehicleIndex == index) {
            _selectedVehicleIndex = -1;
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
              color: isSelected ? colorScheme.secondary : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? colorScheme.secondary : colorScheme.outline),
              boxShadow: (isSelected || Theme.of(context).brightness == Brightness.dark)
                  ? null
                  : [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              color: isSelected ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard(ParkingSpot parking, [String? selectedVehicleType]) {
    final colorScheme = Theme.of(context).colorScheme;
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
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.asset(
                'assets/images/parking_aerial.jpg',
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
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    parking.address,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        parking.rating.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        color: colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${parking.openTime} - ${parking.closeTime}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (parking.isOpen)
                        Text(
                          'OPEN',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                facility,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (parking.vehicles.isNotEmpty) ...[
                    Row(
                      children: parking.vehicles.entries
                          .where((e) => e.value.slots > 0)
                          .map((e) {
                            IconData icon;
                            switch (e.key.toLowerCase()) {
                              case 'bike': icon = Icons.two_wheeler; break;
                              case 'ev': icon = Icons.electric_car; break;
                              case 'suv': icon = Icons.directions_car; break;
                              case 'hatchback': icon = Icons.directions_car_filled; break;
                              default: icon = Icons.local_taxi;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                icon,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          }).toList(),
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
            ? BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Stack(
          children: [
            // Transparent dismissible background
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeOverlay,
                behavior: HitTestBehavior.translucent,
                // Dimmed background
                child: Container(color: Colors.black.withOpacity(0.5)),
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
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline),
                    boxShadow: theme.brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
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
