import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/parking/widgets/circular_duration_slider.dart';
import 'package:parkwise/features/parking/widgets/vehicle_details_popup.dart';
import 'package:parkwise/features/parking/screens/booking_summary_screen.dart';

class ParkingDetailsPopup extends StatefulWidget {
  final ParkingSpot parking;

  const ParkingDetailsPopup({super.key, required this.parking});

  @override
  State<ParkingDetailsPopup> createState() => _ParkingDetailsPopupState();
}

class _ParkingDetailsPopupState extends State<ParkingDetailsPopup> {
  String? _selectedVehicleKey;

  // Slider Integration State
  double _duration = 1.0;
  int _daySelectionIndex = 0;
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Default selection removed as requested
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = widget.parking.vehicles;

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
                    'assets/images/parking_aerial.jpg', // Placeholder since parking.imageUrl might be invalid URL on emulator.
                    // In real app use: widget.parking.imageUrl.startsWith('http') ? NetworkImage(...) : AssetImage(...)
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
                          widget.parking.name,
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
                              widget.parking.rating.toString(),
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
                    widget.parking.address,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
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
                    children: widget.parking.facilities.split(',').map((f) {
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

                  // ------------------------
                  // DURATION SLIDER SECTION
                  // ------------------------
                  if (_selectedVehicleKey != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Start Time Selector
                    Text(
                      'Start Time',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildDateChip('Today', 0),
                        const SizedBox(width: 12),
                        _buildDateChip('Tomorrow', 1),
                        const SizedBox(width: 12),
                        _buildDateChip('Later', 2),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Duration Heading
                    Center(
                      child: Text(
                        'Duration',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Circular Slider
                    Center(
                      child: CircularDurationSlider(
                        value: _duration,
                        min: 0,
                        max: 12,
                        onChanged: (val) => setState(() => _duration = val),
                        activeColor: const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Total Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\u20B9${(widget.parking.vehicles[_selectedVehicleKey]!.price * _duration).toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 80), // Space for bottom slider
                ],
              ),
            ),
          ),

          // Slide Action Button (Show only if vehicle selected)
          if (_selectedVehicleKey != null)
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
                  onSlideCompleted: () async {
                    final type = _selectedVehicleKey!;
                    final data = widget.parking.vehicles[type]!;

                    // Show Vehicle Details Dialog
                    await showDialog(
                      context: context,
                      builder: (context) => VehicleDetailsDialog(
                        vehicleType: type,
                        onProceed: (model, plate) {
                          Navigator.pop(context); // Close Dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingSummaryScreen(
                                spot: widget.parking,
                                slotId: -1,
                                startTime: _selectedDate,
                                duration: _duration,
                                totalPrice: data.price * _duration,
                                vehicleModel: model,
                                licensePlate: plate,
                                hourlyRate: data.price,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, int index) {
    bool isSelected = _daySelectionIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _daySelectionIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4ADE80)
                  : Colors.grey.shade200,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? const Color(0xFF16A34A) : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
