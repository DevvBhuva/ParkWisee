import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/home/widgets/parking_details_popup.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/parking/services/parking_firestore_service.dart';
import 'package:parkwise/features/home/screens/profile_screen.dart';
import 'package:parkwise/features/parking/screens/bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedVehicleIndex = -1; // No vehicle selected by default
  final ParkingFirestoreService _parkingService = ParkingFirestoreService();

  // Search Expand State
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  // Vehicle Categories
  final List<Map<String, dynamic>> _vehicleCategories = [
    {'name': 'Hatchback', 'image': 'assets/images/hatchback_icon.jpg'},
    {'name': 'SUV', 'image': 'assets/images/suv_icon.png'},
    {'name': 'Sedan', 'image': 'assets/images/sedan_icon.jpg'},
    {'name': 'EV', 'image': 'assets/images/ev_icon.jpg'},
    {'name': 'Bike', 'image': 'assets/images/bike_icon.jpg'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              const Center(child: Text("Nav Placeholder")), // Placeholder
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
              // Expandable Search Bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: _isSearchExpanded
                    ? MediaQuery.of(context).size.width - 48 - 60
                    : 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  // Removed shadow/border completely as requested ("remove the border higlighting where to park / remove that")
                ),
                child: Stack(
                  children: [
                    // Text Field
                    if (_isSearchExpanded)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 50),
                          child: Center(
                            child: TextField(
                              controller: _searchController,
                              autofocus: false,
                              decoration: InputDecoration(
                                hintText: 'Where to park ??', // Updated hint
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: GoogleFonts.outfit(color: Colors.black87),
                              onSubmitted: (value) {
                                // Add search logic here if needed
                              },
                            ),
                          ),
                        ),
                      ),

                    // Rolling Search Icon
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      left: _isSearchExpanded
                          ? (MediaQuery.of(context).size.width - 48 - 60) -
                                50 // Move to right end
                          : 0, // Keep at left
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSearchExpanded = !_isSearchExpanded;
                            if (!_isSearchExpanded) {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            }
                          });
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(
                            begin: 0,
                            end: _isSearchExpanded ? 1 : 0,
                          ),
                          duration: const Duration(milliseconds: 400),
                          builder: (context, double value, child) {
                            return Transform.rotate(
                              angle: value * 2 * 3.14159, // Full rotation (2pi)
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
                return Text("Error: ${snapshot.error}");
              }

              final parkings = snapshot.data ?? [];
              // Use first 3 for home screen
              final displayParkings = parkings.take(3).toList();

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: displayParkings.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  return _buildParkingCard(displayParkings[index]);
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
              Expanded(
                child: StreamBuilder<List<ParkingSpot>>(
                  stream: _parkingService.getParkingSpots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final parkings = snapshot.data!;
                    // Filter out the first 3 that are shown on home screen
                    final otherParkings = parkings.skip(3).toList();

                    if (otherParkings.isEmpty) {
                      return Center(
                        child: Text(
                          "No more spots available",
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: otherParkings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
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

  Widget _buildHeaderButton(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        // Removed shadow to match requested simpler search look, or kept minimal if user only complained about search border?
        // User said "remove the border higlighting where to park", specific to search.
        // I'll keep button shadow as it gives depth, unless user complains.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87),
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
                        color: Colors.black.withOpacity(0.05),
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

  Widget _buildParkingCard(ParkingSpot parking) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ParkingDetailsPopup(parking: parking),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  // Title row (Price removed as requested)
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
            color: Colors.black.withOpacity(
              0.1,
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
}
