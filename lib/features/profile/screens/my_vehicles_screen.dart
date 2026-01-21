import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';
import 'package:parkwise/features/profile/services/vehicle_firestore_service.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final VehicleFirestoreService _firestoreService = VehicleFirestoreService();
  late Stream<List<Vehicle>> _vehiclesStream;

  @override
  void initState() {
    super.initState();
    _vehiclesStream = _firestoreService.getVehiclesStream();
  }

  void _showVehicleDialog({Vehicle? vehicle}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Allow clicking outside to dismiss
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.center,
          child: _VehicleDialog(
            vehicle: vehicle,
            onSave: (name, type, plate) async {
              if (vehicle == null) {
                // Add
                final newVehicle = Vehicle(
                  id: '', // Service handles ID
                  name: name,
                  type: type,
                  licensePlate: plate,
                );
                await _firestoreService.addVehicle(newVehicle);
              } else {
                // Update
                final updatedVehicle = Vehicle(
                  id: vehicle.id,
                  name: name,
                  type: type,
                  licensePlate: plate,
                );
                await _firestoreService.updateVehicle(updatedVehicle);
              }
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Animation: Scale from Bottom-Right (FAB position)
        // Curves.easeOutBack gives a nice "pop" effect
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          alignment: Alignment.bottomRight,
          child: child,
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Vehicle?',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this vehicle?',
          style: GoogleFonts.outfit(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _firestoreService.deleteVehicle(id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Vehicles',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Vehicle>>(
        stream: _vehiclesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final vehicles = snapshot.data ?? [];

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No vehicles found",
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade500,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Tap + to add one",
                    style: GoogleFonts.outfit(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: vehicles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return _buildVehicleCard(vehicle);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleDialog(),
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.directions_car_filled,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Changed layout to Wrap or Column to ensure license plate is visible
                  // Using Column for stricter control: Type above, Plate below (or vice versa)
                  // Or Wrap if we want them side-by-side but wrapping if needed.
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag(vehicle.type),
                      Text(
                        vehicle.licensePlate,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min, // Prevent taking up extra space
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => _showVehicleDialog(vehicle: vehicle),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  onPressed: () => _confirmDelete(vehicle.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

// Separate Widget for Dialog state management
class _VehicleDialog extends StatefulWidget {
  final Vehicle? vehicle;
  final Function(String, String, String) onSave;

  const _VehicleDialog({this.vehicle, required this.onSave});

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _plateController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.name ?? '');
    _typeController = TextEditingController(text: widget.vehicle?.type ?? '');
    _plateController = TextEditingController(
      text: widget.vehicle?.licensePlate ?? '',
    );
    _validate();
  }

  void _validate() {
    setState(() {
      _isValid =
          _nameController.text.isNotEmpty &&
          _typeController.text.isNotEmpty &&
          _plateController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen height and keyboard height to adjust max height if needed
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white, // White Background
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.9, // Prevent overflowing screen
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Dark text
                ),
              ),
              const SizedBox(height: 24),
              _buildLightTextField(
                controller: _nameController,
                label: 'Vehicle Name',
                hint: 'e.g. My Tesla',
                icon: Icons.title,
              ),
              const SizedBox(height: 16),
              _buildLightTextField(
                controller: _typeController,
                label: 'Vehicle Type',
                hint: 'e.g. SUV, EV',
                icon: Icons.category,
              ),
              const SizedBox(height: 16),
              _buildLightTextField(
                controller: _plateController,
                label: 'License Plate',
                hint: 'e.g. ABC 123',
                icon: Icons.confirmation_number,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? () {
                              widget.onSave(
                                _nameController.text,
                                _typeController.text,
                                _plateController.text,
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Dark button
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Add extra padding at bottom if keyboard is open to ensure visibility if needed
              // Though SingleChildScrollView + Dialog inset usually handles it.
              if (isKeyboardOpen)
                SizedBox(height: mediaQuery.viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.black87, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => _validate(),
          style: GoogleFonts.outfit(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade500),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
