import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';

import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/home/widgets/slide_to_book_button.dart';
import 'package:parkwise/features/parking/widgets/circular_duration_slider.dart';
import 'package:parkwise/features/parking/widgets/vehicle_details_popup.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';
import 'package:parkwise/features/parking/screens/booking_summary_screen.dart';

// ... (existing imports)

// ... (existing imports)

class BookingScreen extends StatefulWidget {
  final ParkingSpot spot;
  final String vehicleType;
  final double pricePerHour;
  final int availableSlots;

  const BookingScreen({
    super.key,
    required this.spot,
    required this.vehicleType,
    required this.pricePerHour,
    required this.availableSlots,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedSlotId = -1; // -1 means none selected
  int _selectedLevel = 1; // Default to Level 1

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now(); // Added time state

  double _duration = 1.0; // Hours
  int _daySelectionIndex = 0; // 0: Today, 1: Tomorrow, 2: Later

  final BookingFirestoreService _bookingService = BookingFirestoreService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Periodically refresh the UI to update slot availability based on current time
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Helper to check if a specific slot is currently occupied based on its active bookings
  bool _isSlotOccupied(int slotId, List<Booking> bookings) {
    final now = DateTime.now();
    for (var booking in bookings) {
      if (booking.slotId == slotId) {
        // A slot is occupied if 'now' is within the range [startTime, endTime]
        if (now.isAfter(booking.startTime) && now.isBefore(booking.endTime)) {
          return true;
        }
      }
    }
    return false;
  }


  void _showBookingDetails() {
    // ... (same as before)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final totalPrice = widget.pricePerHour * _duration;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: theme.brightness == Brightness.light 
                  ? [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
                border: Border(top: BorderSide(color: colorScheme.outline)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Name & Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.spot.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Slot P${_selectedSlotId + 1}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\u20B9${widget.pricePerHour.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '/ hour',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Selector
                            Text(
                              'Start Time',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildDateChip('Today', 0, setSheetState),
                              const SizedBox(width: 12),
                              _buildDateChip('Tomorrow', 1, setSheetState),
                              const SizedBox(width: 12),
                              _buildDateChip('Later', 2, setSheetState),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Slot Time Selection
                          Text(
                            'Time',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        backgroundColor: Colors.white,
                                        dialHandColor: Colors.green,
                                        dialBackgroundColor:
                                            Colors.grey.shade100,
                                        hourMinuteTextColor:
                                            Colors.green.shade800,
                                        dayPeriodTextColor:
                                            Colors.green.shade800,
                                        entryModeIconColor: Colors.green,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.green,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  _selectedTime = time;
                                  // Update _selectedDate with new time
                                  _selectedDate = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                                setSheetState(() {});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outline),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedTime.format(context),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Change',
                                    style: GoogleFonts.outfit(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Duration Heading
                          Center(
                            child: Text(
                              'Duration',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Circular Slider
                          Center(
                            child: CircularDurationSlider(
                              value: _duration,
                              min: 0,
                              max: 23,
                              onChanged: (val) {
                                setState(() => _duration = val);
                                setSheetState(() {});
                              },
                              activeColor: const Color(0xFF00C853),
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
                                '\u20B9${totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00C853),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Slide to Pay Button
                          SizedBox(
                            height: 60,
                            child: SlideToBookButton(
                              label: 'Slide to Proceed',
                              completionLabel: 'Proceeding',
                              onCompleted: () async {
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                if (context.mounted) {
                                  // Reset slider state if needed?
                                  // For now, proceed to open popup
                                  showDialog(
                                    context: context,
                                    builder: (context) => VehicleDetailsDialog(
                                      vehicleType: widget.vehicleType,
                                      onProceed: (model, plate) async {
                                        await Future.delayed(
                                          const Duration(seconds: 1),
                                        );
                                        if (!context.mounted) return;
                                        Navigator.pop(
                                          context,
                                        ); // Close loading dialog
                                        Navigator.pop(context); // Close Dialog
                                        Navigator.pop(context); // Close Sheet

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BookingSummaryScreen(
                                                  spot: widget.spot,
                                                  slotId: _selectedSlotId,
                                                  startTime: _selectedDate,
                                                  duration: _duration,
                                                  totalPrice:
                                                      widget.pricePerHour *
                                                      _duration,
                                                  vehicleModel: model,
                                                  licensePlate: plate,
                                                  hourlyRate:
                                                      widget.pricePerHour,
                                                  vehicleType: widget
                                                      .vehicleType, // Pass correct vehicle category
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Slot',
          style: GoogleFonts.outfit(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingService.getActiveBookingsForSpot(
          widget.spot.id,
          widget.vehicleType,
        ),
        builder: (context, snapshot) {
          final allBookings = snapshot.data ?? [];
          final now = DateTime.now();

          // Filter only those bookings that haven't ended yet
          final activeBookings = allBookings.where((b) {
            return b.endTime.isAfter(now);
          }).toList();


          // ---------------------------------------------------------
          // SMART LEVEL CALCULATION & DISTRIBUTION
          // ---------------------------------------------------------
          final stats = _calculateLevelStats(
            widget.availableSlots,
            widget.vehicleType,
            _selectedLevel,
          );

          final totalLevels = stats['totalLevels']!;
          final startSlotIndex = stats['start']!;
          final endSlotIndex = stats['end']!;
          final currentLevelSlotCount = endSlotIndex - startSlotIndex;



          return Column(
            children: [
              // ------------------------------------------
              // FULL SCREEN SLOT GRID
              // ------------------------------------------
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Lane Labels & Arrows
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'ENTRY',
                                  style: GoogleFonts.outfit(
                                    color: colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_downward,
                                  color: colorScheme.secondary,
                                  size: 24,
                                ),
                              ],
                            ),
                            // Road Markings (Dashed Line)
                            Container(
                              height: 40,
                              width: 2,
                              decoration: BoxDecoration(
                                color: colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'EXIT',
                                  style: GoogleFonts.outfit(
                                    color: colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_upward,
                                  color: colorScheme.error,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Level Selector
                      _buildLevelSelector(totalLevels),

                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeOutQuart,
                          switchOutCurve: Curves.easeInQuart,
                          transitionBuilder: (child, animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0.1, 0.0),
                              end: Offset.zero,
                            ).animate(animation);

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: GridView.builder(
                            key: ValueKey('level_$_selectedLevel'),
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: currentLevelSlotCount,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 60,
                              mainAxisSpacing: 24,
                              childAspectRatio: 2.2,
                            ),
                            itemBuilder: (context, index) {
                              // Map local grid index to global slot index
                              final globalIndex = startSlotIndex + index;
                              final slotNumber = globalIndex + 1;

                              // Check if this specific global index is in occupied list
                              final isBooked =
                                  _isSlotOccupied(globalIndex, activeBookings);
                              final isSelected = _selectedSlotId == globalIndex;


                              // Visuals for Booked Slot
                              if (isBooked) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.error.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'P$slotNumber',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: colorScheme.error.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        Text(
                                          'Booked',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: colorScheme.error.withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSlotId = globalIndex;
                                  });
                                  _showBookingDetails();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                                        : colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: (isSelected || theme.brightness == Brightness.dark)
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: colorScheme.shadow,
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'P$slotNumber',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Available',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, int> _calculateLevelStats(
    int totalSlots,
    String vehicleType,
    int currentLevel,
  ) {
    if (totalSlots <= 0) return {'totalLevels': 1, 'start': 0, 'end': 0};

    final type = vehicleType.toLowerCase();
    int totalLevels;

    if (type.contains('bike')) {
      if (totalSlots <= 20) {
        totalLevels = 1;
      } else if (totalSlots <= 40) {
        totalLevels = 2;
      } else if (totalSlots <= 80) {
        totalLevels = 3;
      } else {
        totalLevels = (totalSlots / 25).ceil();
      }
    } else {
      // Car / Hatchback / SUV
      if (totalSlots <= 12) {
        totalLevels = 1;
      } else if (totalSlots <= 24) {
        totalLevels = 2;
      } else if (totalSlots <= 45) {
        totalLevels = 3;
      } else {
        totalLevels = (totalSlots / 15).ceil();
      }
    }

    // Adjust current level if it exceeds calculated levels
    if (_selectedLevel > totalLevels) {
      _selectedLevel = totalLevels;
    }

    // EVEN DISTRIBUTION MATH
    final baseSize = totalSlots ~/ totalLevels;
    final remainder = totalSlots % totalLevels;

    int calculateStart(int level) {
      if (level <= remainder) {
        return (level - 1) * (baseSize + 1);
      } else {
        return remainder * (baseSize + 1) + (level - remainder - 1) * baseSize;
      }
    }

    int calculateEnd(int level) {
      if (level <= remainder) {
        return level * (baseSize + 1);
      } else {
        return remainder * (baseSize + 1) + (level - remainder) * baseSize;
      }
    }

    return {
      'totalLevels': totalLevels,
      'start': calculateStart(_selectedLevel),
      'end': calculateEnd(_selectedLevel),
    };
  }


  Widget _buildLevelSelector(int totalLevels) {
    if (totalLevels <= 1) return const SizedBox.shrink();

    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: totalLevels,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final level = index + 1;
          final isSelected = _selectedLevel == level;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLevel = level;
                _selectedSlotId = -1; // Reset selection on level change
              });
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isSelected ? 1.05 : 1.0,
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Center(
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Floor $level',
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildDateChip(String label, int index, StateSetter setSheetState) {

    bool isSelected = _daySelectionIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _daySelectionIndex = index);
          DateTime baseDate;

          if (index == 2) {
            // Later -> Custom Themed Calendar
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.green.shade700,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                      ),
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date == null) return;
            baseDate = date;
          } else if (index == 0) {
            baseDate = DateTime.now();
            // If checking 'Today', maybe we want to reset time to now if the *current* selected time is in past?
            // For simplicity, let's keep selected time if possible, or reset to now if it's earlier than now?
            // User can just pick time. Let's just use base date year/month/day.
          } else {
            // Tomorrow
            baseDate = DateTime.now().add(const Duration(days: 1));
          }

          setState(() {
            _selectedDate = DateTime(
              baseDate.year,
              baseDate.month,
              baseDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );
          });
          setSheetState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green.shade200 : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
