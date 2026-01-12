import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/home/screens/placeholder_screens.dart';
import 'package:parkwise/features/home/screens/profile_screen.dart';

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
              borderRadius: BorderRadius.circular(100), // Full Pill Shape
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
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Placeholder Background
        Container(color: Colors.grey.shade50),

        // Content Overlay
        SafeArea(
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
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
