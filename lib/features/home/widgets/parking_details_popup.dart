import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';

import 'package:parkwise/features/parking/screens/booking_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

// ... (existing imports)

class ParkingDetailsPopup extends StatefulWidget {
  final ParkingSpot parking;
  final String? initialVehicleType;

  const ParkingDetailsPopup({
    super.key,
    required this.parking,
    this.initialVehicleType,
  });

  @override
  State<ParkingDetailsPopup> createState() => _ParkingDetailsPopupState();
}

class _ParkingDetailsPopupState extends State<ParkingDetailsPopup> {
  String? _selectedVehicleKey;
  late Stream<DocumentSnapshot> _parkingStream;

  @override
  void initState() {
    super.initState();
    // Auto-select if provided and valid
    if (widget.initialVehicleType != null &&
        widget.parking.vehicles.containsKey(widget.initialVehicleType)) {
      _selectedVehicleKey = widget.initialVehicleType;
    }

    // Listen to real-time updates for this parking spot
    _parkingStream = FirebaseFirestore.instance
        .collection('parkings')
        .doc(widget.parking.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _parkingStream,
      builder: (context, snapshot) {
        ParkingSpot displayParking = widget.parking;

        if (snapshot.hasData && snapshot.data!.exists) {
          try {
            // Update the parking object with new data
            displayParking = ParkingSpot.fromFirestore(snapshot.data!);
          } catch (e) {
            print('Error parsing real-time update: $e');
            // Fallback to widget.parking
          }
        }

        final vehicles = displayParking.vehicles;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Image
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Image.asset(
                        'assets/images/parking_aerial.jpg', // Placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Close Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayParking.name,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayParking.rating.toString(),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayParking.address,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Facilities
                      Text(
                        'Facilities',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: displayParking.facilities.split(',').map((f) {
                          final facility = f.trim();
                          if (facility.isEmpty) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              facility,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Vehicle Selection
                      Text(
                        'Choose Vehicle Type',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (vehicles.isEmpty)
                        Text(
                          'No pricing info available',
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),

                      // Filter out vehicles with 0 slots
                      ...vehicles.entries.where((e) => e.value.slots > 0).map((
                        entry,
                      ) {
                        final type = entry.key;
                        final data = entry.value;
                        final isSelected = _selectedVehicleKey == type;

                        // "if user selects vehicle then green colour appears"
                        final activeColor = const Color(0xFF4ADE80);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedVehicleKey == type) {
                                _selectedVehicleKey = null;
                              } else {
                                _selectedVehicleKey = type;
                                // Force rebuild of slider state via Key
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves
                                .easeInOut, // "make rest of txt visible in ease"
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 1. Vehicle Type (Left)
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    type.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black, // Always black
                                    ),
                                  ),
                                ),

                                // 2. Number of Slots (Middle)
                                Expanded(
                                  flex: 4,
                                  child: Center(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${data.slots} ',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.black
                                                  : const Color(
                                                      0xFF16A34A,
                                                    ), // Dynamic color
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'slots',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. Price (Right)
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '\u20B9${data.price}/hr',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 80), // Space for bottom slider
                    ],
                  ),
                ),
              ),

              // Slide Action Button (Show only if vehicle selected)
              if (_selectedVehicleKey != null &&
                  vehicles.containsKey(_selectedVehicleKey) &&
                  vehicles[_selectedVehicleKey]!.slots > 0)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: _SlideToBookButton(
                      key: ValueKey(_selectedVehicleKey),
                      onSlideCompleted: () {
                        final type = _selectedVehicleKey!;
                        final data = vehicles[type]!;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              spot: displayParking,
                              vehicleType: type,
                              pricePerHour: data.price,
                              availableSlots: data.slots,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SlideToBookButton extends StatefulWidget {
  final VoidCallback onSlideCompleted;

  const _SlideToBookButton({super.key, required this.onSlideCompleted});

  @override
  State<_SlideToBookButton> createState() => _SlideToBookButtonState();
}

class _SlideToBookButtonState extends State<_SlideToBookButton> {
  double _dragValue = 0.0;
  bool _isCompleted = false;
  final double _height = 60.0;
  final double _knobWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    // Interpolate Color: Black -> Green
    final Color bgColor = Color.lerp(
      Colors.black,
      const Color(0xFF4ADE80),
      _dragValue,
    )!;
    // Interpolate Text Color: White -> Black
    final Color textColor = Color.lerp(Colors.white, Colors.black, _dragValue)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxDrag = maxWidth - _knobWidth;

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Text
              Center(
                child: Text(
                  _isCompleted ? 'Book Slot' : 'Slide to proceed',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              // Draggable Knob
              Positioned(
                left: _dragValue * maxDrag,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;

                    double delta = details.primaryDelta ?? 0;
                    double currentPos = _dragValue * maxDrag;
                    double newPos = currentPos + delta;

                    // Clamp
                    double newDragValue = (newPos / maxDrag).clamp(0.0, 1.0);

                    setState(() {
                      _dragValue = newDragValue;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted) return;

                    if (_dragValue > 0.6) {
                      // Complete action
                      setState(() {
                        _dragValue = 1.0;
                        _isCompleted = true;
                      });
                      // Small delay before triggering navigation to show completed state
                      Future.delayed(const Duration(milliseconds: 200), () {
                        widget.onSlideCompleted();
                        // Reset after navigation returns?
                        // If we want to reset:
                        if (mounted) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted)
                              setState(() {
                                _dragValue = 0.0;
                                _isCompleted = false;
                              });
                          });
                        }
                      });
                    } else {
                      // Spring back
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: _knobWidth,
                    height: _height,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded, // Stemless arrow
                      color: Colors.black,
                      size: 20,
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
}
