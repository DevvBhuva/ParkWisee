import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/home/models/location_model.dart';

class CitySelectionPopup extends StatelessWidget {
  final List<City> cities;
  final Function(City) onCitySelected;
  final VoidCallback onClose;

  const CitySelectionPopup({
    super.key,
    required this.cities,
    required this.onCitySelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select City',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: cities.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final city = cities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    city.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  // trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // REMOVED
                  onTap: () {
                    // Navigator.pop(context); // REMOVED
                    onCitySelected(city);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
