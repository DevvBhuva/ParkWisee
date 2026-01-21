import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:parkwise/features/home/widgets/slide_to_book_button.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';
import 'package:parkwise/features/profile/services/vehicle_firestore_service.dart';

class VehicleDetailsDialog extends StatefulWidget {
  final String vehicleType;
  final Function(String, String) onProceed;

  const VehicleDetailsDialog({
    super.key,
    required this.vehicleType,
    required this.onProceed,
  });

  @override
  State<VehicleDetailsDialog> createState() => _VehicleDetailsDialogState();
}

class _VehicleDetailsDialogState extends State<VehicleDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final VehicleFirestoreService _firestoreService = VehicleFirestoreService();

  bool _isValid = false;
  String? _selectedVehicleId; // null means "Enter Manually"

  @override
  void initState() {
    super.initState();
    // Validate initially? No, fields empty.
  }

  void _validate() {
    setState(() {
      _isValid = _formKey.currentState?.validate() ?? false;
    });
  }

  void _onSavedVehicleSelected(Vehicle? vehicle) {
    setState(() {
      if (vehicle != null) {
        _selectedVehicleId = vehicle.id;
        _modelController.text = vehicle.name;
        _plateController.text = vehicle.licensePlate;
        _isValid = true; // Saved vehicles assumed valid? Or validate again.
        _formKey.currentState?.validate();
      } else {
        _selectedVehicleId = null;
        _modelController.clear();
        _plateController.clear();
        _isValid = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Details',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Saved Vehicles Dropdown
              StreamBuilder<List<Vehicle>>(
                stream: _firestoreService.getVehiclesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final vehicles = snapshot.data!;
                  // Filter by type? "and type of vehicle is preselected".
                  // If user selected "Car" slot, maybe filter only Cars?
                  // User said "give option to use from saved vehicles if user select vehicle form there then this form will be disable".
                  // I'll filter by widget.vehicleType if possible, or show all.
                  // Let's filter to be helpful.
                  final filteredVehicles =
                      vehicles; // .where((v) => v.type == widget.vehicleType).toList();
                  // Actually, strict filtering might hide relevant vehicles if types don't match exactly string-wise.
                  // Let's show all for now or maybe just matching ones.

                  if (filteredVehicles.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedVehicleId,
                        hint: Text(
                          'Select Saved Vehicle',
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Enter Details Manually'),
                          ),
                          ...filteredVehicles.map((v) {
                            return DropdownMenuItem<String?>(
                              value: v.id,
                              child: Text('${v.name} (${v.licensePlate})'),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val == null) {
                            _onSavedVehicleSelected(null);
                          } else {
                            final v = filteredVehicles.firstWhere(
                              (element) => element.id == val,
                            );
                            _onSavedVehicleSelected(v);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),

              Form(
                key: _formKey,
                onChanged: _validate,
                child: Column(
                  children: [
                    // Vehicle Type (Read Only)
                    TextFormField(
                      initialValue: widget.vehicleType,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Model
                    TextFormField(
                      controller: _modelController,
                      enabled: _selectedVehicleId == null, // Disable if saved
                      decoration: InputDecoration(
                        labelText: 'Vehicle Model',
                        hintText: 'e.g. Swift, City',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _selectedVehicleId == null
                            ? Colors.grey.shade50
                            : Colors.grey.shade100,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // License Plate
                    TextFormField(
                      controller: _plateController,
                      enabled: _selectedVehicleId == null, // Disable if saved
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [_LicensePlateFormatter()],
                      decoration: InputDecoration(
                        labelText: 'License Plate',
                        hintText: 'GJ 01 AB 1234',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _selectedVehicleId == null
                            ? Colors.grey.shade50
                            : Colors.grey.shade100,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        // Flexible Regex:
                        // State: 2 chars
                        // District: 1-2 digits
                        // Series: 1-3 chars (allowing flexible per user request "x or xx")
                        // Number: 4 digits
                        final regex = RegExp(
                          r'^[A-Z]{2} [0-9]{1,2} [A-Z]{1,3} [0-9]{4}$',
                        );
                        if (!regex.hasMatch(val)) {
                          return 'Invalid Format (e.g. GJ 1 A 1234)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Opacity(
                opacity: _isValid ? 1.0 : 0.5,
                child: AbsorbPointer(
                  absorbing: !_isValid,
                  child: SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: SlideToBookButton(
                      label: 'Slide to Proceed',
                      completionLabel: 'Proceeding',
                      onCompleted: () async {
                        if (_isValid) {
                          widget.onProceed(
                            _modelController.text,
                            _plateController.text,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LicensePlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Clean input: Remove spaces, Uppercase
    String text = newValue.text.toUpperCase().replaceAll(' ', '');
    // Max length guess: 2+2+3+4 = 11 chars.
    if (text.length > 11) text = text.substring(0, 11);

    final buffer = StringBuffer();

    // 2. State (First 2 chars)
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      // Space after State (Index 1)
      if (i == 1 && text.length > 2) {
        buffer.write(' ');
      }

      // Smart Space Logic for District and Series
      // We are past State (i >= 2)
      if (i >= 2 && i < text.length - 1) {
        final currentChar = text[i];
        final nextChar = text[i + 1];

        // If Digit -> Letter (End of District)
        if (_isDigit(currentChar) && _isLetter(nextChar)) {
          buffer.write(' ');
        }

        // If Letter -> Digit (End of Series)
        // Note: State (Letters) -> District (Digits) is handled by index 1 check?
        // Actually index 1 check puts space after 'J' in 'GJ'. Next is '1'.
        // So 'GJ 1...'.
        // What if user types 'GJ1'? 'J' is letter, '1' is digit.
        // My index 1 check handles the first mandatory space.
        // 'J' (index 1) -> ' ' added.
        // Buffer has 'GJ '.

        // Now District '1'. Next 'A'.
        // '1' is digit. 'A' is letter. Add space.
        // Buffer 'GJ 1 '.

        // Now Series 'A'. Next '1' (from 1234).
        // 'A' is letter. '1' is digit. Add space.
        // Buffer 'GJ 1 A '.
        // Then '1234'.

        if (_isLetter(currentChar) && _isDigit(nextChar)) {
          buffer.write(' ');
        }
      }
    }

    String newText = buffer.toString();
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  bool _isDigit(String char) => RegExp(r'[0-9]').hasMatch(char);
  bool _isLetter(String char) => RegExp(r'[A-Z]').hasMatch(char);
}
