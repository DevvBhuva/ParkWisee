import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/home/screens/placeholder_screens.dart';
import 'package:parkwise/features/home/screens/profile_screen.dart';
import 'package:parkwise/features/home/widgets/notification_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HomeTabContent(), // Extracted widget for Home Tab
    BookingScreen(),
    NavigationScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Scaffold(
        // appBar: removed as requested
        backgroundColor: Colors.white, // Uniform background
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: _pages.elementAt(_selectedIndex),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = constraints.maxWidth / 4;
                return SizedBox(
                  height: 80, // Fixed height for the bar
                  child: Stack(
                    children: [
                      // Sliding Green Indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        top: 5,
                        left: _selectedIndex * itemWidth + 5,
                        width: itemWidth - 10,
                        height: 70,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 69, 255, 66),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      // Navigation Items
                      Row(
                        children: [
                          _buildNavItem(
                            0,
                            Icons.home_rounded,
                            Icons.home_outlined,
                            'Home',
                            itemWidth,
                          ),
                          _buildNavItem(
                            1,
                            Icons.calendar_month_rounded,
                            Icons.calendar_month_outlined,
                            'Booking',
                            itemWidth,
                          ),
                          _buildNavItem(
                            2,
                            Icons.near_me_rounded,
                            Icons.near_me_outlined,
                            'Nav',
                            itemWidth,
                          ),
                          _buildNavItem(
                            3,
                            Icons.person_rounded,
                            Icons.person_outline,
                            'Profile',
                            itemWidth,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    double width,
  ) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.black : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            // Text Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.black : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent();

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  bool _isExpanded = false;
  bool _isNotificationOpen = false;
  final TextEditingController _searchController = TextEditingController();

  int _selectedVehicleIndex = -1;
  final List<Map<String, String>> _vehicleTypes = [
    {'name': 'Hatchback', 'icon': 'assets/images/hatchback_icon.jpg'},
    {'name': 'SUV', 'icon': 'assets/images/suv_icon.png'},
    {'name': 'Sedan', 'icon': 'assets/images/sedan_icon.jpg'},
    {'name': 'EV', 'icon': 'assets/images/ev_icon.jpg'},
    {'name': 'Bike', 'icon': 'assets/images/bike_icon.jpg'},
  ];

  final List<Map<String, dynamic>> _parkingSpots = [
    {
      'name': 'Grand Mall Parking',
      'address': '123 Main St, Central City',
      'price': '\$5/hr',
      'rating': 4.5,
      'image': 'assets/images/parking_aerial.jpg',
    },
    {
      'name': 'City Center Garage',
      'address': '456 Market St, Downtown',
      'price': '\$4/hr',
      'rating': 4.2,
      'image': 'assets/images/parking_login.jpg',
    },
    {
      'name': 'Airport Terminal 1',
      'address': '789 Airport Rd, Westside',
      'price': '\$8/hr',
      'rating': 4.8,
      'image': 'assets/images/parking_aerial.jpg',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _searchController.clear();
        FocusScope.of(context).unfocus(); // Close keyboard on collapse
      }
    });
  }

  void _toggleNotifications() {
    setState(() {
      _isNotificationOpen = !_isNotificationOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Placeholder Background
        Container(color: Colors.grey.shade50),

        // Content Overlay
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16), // Padding from top safe area
                // Search and Notification Buttons Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Animated Search Bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeInOutCubic,
                        // Logic: If expanded, take 70% of screen. If collapsed, only 50px circle.
                        width: _isExpanded
                            ? MediaQuery.of(context).size.width * 0.70
                            : 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            30,
                          ), // Pill shape when expanded, Circle when collapsed
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isExpanded)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: TextField(
                                    controller: _searchController,
                                    cursorColor: Colors.black,
                                    decoration: InputDecoration(
                                      hintText: 'Search parking...',
                                      hintStyle: GoogleFonts.outfit(
                                        color: Colors.grey.shade400,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: GoogleFonts.outfit(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            // Search Icon (Acts as Toggle with Rolling Animation)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleSearch,
                                borderRadius: BorderRadius.circular(30),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: AnimatedRotation(
                                    turns: _isExpanded ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 450),
                                    curve: Curves.easeInOutCubic,
                                    child: const Icon(
                                      Icons.search,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Notification Button
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _toggleNotifications,
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Choose Vehicle Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Vehicle',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90, // Reduced height
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _vehicleTypes.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            bool isSelected = _selectedVehicleIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVehicleIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ), // Reduced padding
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color.fromARGB(255, 69, 255, 66)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // Reduced radius
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: isSelected
                                      ? null
                                      : Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50, // Reduced width
                                      height: 30, // Reduced height
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            _vehicleTypes[index]['icon']!,
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _vehicleTypes[index]['name']!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12, // Reduced font size
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Parking Spot Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Parking Spot',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'See All',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color.fromARGB(255, 69, 255, 66),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _parkingSpots.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final spot = _parkingSpots[index];
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                Container(
                                  height:
                                      150, // Slightly taller for vertical view
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    image: DecorationImage(
                                      image: AssetImage(spot['image']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              spot['name'],
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                20,
                                                69,
                                                255,
                                                66,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              spot['price'],
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: const Color.fromARGB(
                                                  255,
                                                  0,
                                                  180,
                                                  0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        spot['address'],
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Colors.amber,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            spot['rating'].toString(),
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.access_time_rounded,
                                            color: Colors.grey.shade400,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Open 24/7',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Notification Overlay
        NotificationPopup(
          isOpen: _isNotificationOpen,
          onToggle: _toggleNotifications,
        ),
      ],
    );
  }
}
