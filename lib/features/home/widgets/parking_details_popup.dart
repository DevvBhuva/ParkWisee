import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: _parkingStream,
      builder: (context, snapshot) {
        ParkingSpot displayParking = widget.parking;

        if (snapshot.hasData && snapshot.data!.exists) {
          try {
            displayParking = ParkingSpot.fromFirestore(snapshot.data!);
          } catch (e) {
            debugPrint('Error refetching parking: $e');
          }
        }

        final vehicles = displayParking.vehicles;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Image
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      child: Image.asset(
                        'assets/images/parking_aerial.jpg',
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
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: theme.brightness == Brightness.light
                              ? [
                                  BoxShadow(
                                    color: colorScheme.shadow,
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                          border: theme.brightness == Brightness.dark
                              ? Border.all(color: colorScheme.outline)
                              : null,
                        ),
                        child: Icon(Icons.close, size: 20, color: colorScheme.onSurface),
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
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayParking.rating.toString(),
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayParking.address,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Facilities
                      Text(
                        'Facilities',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
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
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              facility,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Vehicle Selection
                      Text(
                        'Choose Vehicle Type',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (vehicles.isEmpty)
                        Text(
                          'No pricing info available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),

                      ...vehicles.entries.where((e) => e.value.slots > 0).map((entry) {
                        final type = entry.key;
                        final data = entry.value;
                        final isSelected = _selectedVehicleKey == type;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedVehicleKey == type) {
                                _selectedVehicleKey = null;
                              } else {
                                _selectedVehicleKey = type;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? colorScheme.secondaryContainer : colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? colorScheme.secondary : colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.secondary.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    type.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Center(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${data.slots} ',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.secondary,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'slots available',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: isSelected ? colorScheme.onSecondaryContainer.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '\u20B9${data.price}/hr',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Slide Action Button
              if (_selectedVehicleKey != null &&
                  vehicles.containsKey(_selectedVehicleKey) &&
                  vehicles[_selectedVehicleKey]!.slots > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(top: BorderSide(color: colorScheme.outline)),
                    boxShadow: theme.brightness == Brightness.light
                      ? [
                          BoxShadow(
                            color: colorScheme.shadow,
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ]
                      : null,
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
  final double _height = 64.0;
  final double _knobWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bgColor = Color.lerp(
      colorScheme.secondaryContainer,
      colorScheme.secondary,
      _dragValue,
    )!;

    final Color textColor = Color.lerp(
      colorScheme.onSecondaryContainer,
      colorScheme.onSecondary,
      _dragValue,
    )!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxDrag = maxWidth - _knobWidth - 8;

        return Container(
          height: _height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Opacity(
                  opacity: 1.0 - (_dragValue * 0.5),
                  child: Text(
                    _isCompleted ? 'Booking...' : 'Slide to Book Spot',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 4 + (_dragValue * maxDrag),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;
                    double delta = details.primaryDelta ?? 0;
                    double currentPos = _dragValue * maxDrag;
                    double newPos = currentPos + delta;
                    setState(() {
                      _dragValue = (newPos / maxDrag).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted) return;

                    if (_dragValue > 0.7) {
                      setState(() {
                        _dragValue = 1.0;
                        _isCompleted = true;
                      });
                      Future.delayed(const Duration(milliseconds: 200), () {
                        widget.onSlideCompleted();
                        if (mounted) {
                          Future.delayed(const Duration(milliseconds: 1000), () {
                            if (mounted) {
                              setState(() {
                                _dragValue = 0.0;
                                _isCompleted = false;
                              });
                            }
                          });
                        }
                      });
                    } else {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: _knobWidth,
                    height: _height - 8,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: theme.brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: colorScheme.shadow,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                      border: theme.brightness == Brightness.dark
                        ? Border.all(color: colorScheme.outline)
                        : null,
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      color: _isCompleted ? Theme.of(context).colorScheme.primary : colorScheme.secondary,
                      size: 24,
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
