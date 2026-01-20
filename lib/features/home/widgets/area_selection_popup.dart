import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/home/models/location_model.dart';
import 'package:flutter/services.dart';

class AreaSelectionPopup extends StatefulWidget {
  final City city;
  final List<Area> areas;
  final Function(Area) onAreaSelected;
  final VoidCallback onClose;

  const AreaSelectionPopup({
    super.key,
    required this.city,
    required this.areas,
    required this.onAreaSelected,
    required this.onClose,
  });

  @override
  State<AreaSelectionPopup> createState() => _AreaSelectionPopupState();
}

class _AreaSelectionPopupState extends State<AreaSelectionPopup> {
  List<Area> _filteredAreas = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredAreas = widget.areas;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAreas = widget.areas.where((area) {
        return area.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Make popup fullscreen or large enough
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
                'Select Area in ${widget.city.name}',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey.shade500),
                hintText: 'Search in ${widget.city.name}...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: GoogleFonts.outfit(color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _filteredAreas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No areas found",
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredAreas.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final area = _filteredAreas[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          area.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        onTap: () {
                          // Navigator.pop(context); // REMOVED
                          widget.onAreaSelected(area);
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
