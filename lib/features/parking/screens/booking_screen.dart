import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now(); // Added time state

  double _duration = 1.0; // Hours
  int _daySelectionIndex = 0; // 0: Today, 1: Tomorrow, 2: Later

  final BookingFirestoreService _bookingService = BookingFirestoreService();

  void _showBookingDetails() {
    // ... (same as before)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final totalPrice = widget.pricePerHour * _duration;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75, // 75% height
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
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
                                      ),
                                    ),
                                    Text(
                                      'Slot P${_selectedSlotId + 1}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
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
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedTime.format(context),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Change',
                                    style: GoogleFonts.outfit(
                                      color: Colors.green,
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Slot',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<int>>(
        stream: _bookingService.getOccupiedSlots(
          widget.spot.id,
          widget.vehicleType,
        ),
        builder: (context, snapshot) {
          final occupiedSlots = snapshot.data ?? [];

          // Determine grid size.
          // Problem: availableSlots decreases when booked.
          // BUT we want to show all slots (e.g. 10).
          // Heuristic: total = currentAvailable + bookedCount
          // If a new booking happens, available decreases, occupied increases. Total stays same.
          // Use availableSlots as the total count to prevent grid expansion (e.g. 10 + 1 = 11).
          // This assumes availableSlots might be the total capacity or acceptable to show.
          final totalEffectiveSlots = widget.availableSlots;

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
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ],
                            ),
                            // Road Markings (Dashed Line)
                            Container(
                              height: 40,
                              width: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'EXIT',
                                  style: GoogleFonts.outfit(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          // Use calculated total so grid doesn't shrink
                          itemCount: totalEffectiveSlots > 0
                              ? totalEffectiveSlots
                              : widget.availableSlots,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 60,
                                mainAxisSpacing: 24,
                                childAspectRatio: 2.2,
                              ),
                          itemBuilder: (context, index) {
                            final slotNumber = index + 1;
                            // Check if this specific index is in occupied list
                            // We stored 'slotId' in the booking document.
                            // Assuming 'slotId' corresponds to 'index'.
                            final isBooked = occupiedSlots.contains(index);
                            final isSelected = _selectedSlotId == index;

                            // Visuals for Booked Slot
                            if (isBooked) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'P$slotNumber',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.red.shade300,
                                        ),
                                      ),
                                      Text(
                                        'Booked',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.red.shade300,
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
                                  _selectedSlotId = index;
                                });
                                _showBookingDetails();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green.shade50
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'P$slotNumber',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: isSelected
                                              ? Colors.green.shade800
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Available',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.green,
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
