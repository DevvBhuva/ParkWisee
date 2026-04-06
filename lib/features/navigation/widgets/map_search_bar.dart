import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:parkwise/features/navigation/providers/map_provider.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({super.key});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 16,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Search Box with Scale & Elevation Animation
          AnimatedScale(
            scale: _isFocused ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Material(
              elevation: _isFocused ? 12 : 6,
              shadowColor: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.blueAccent : Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: mapProvider.searchController,
                        onTap: () => mapProvider.toggleSearch(true),
                        onChanged: mapProvider.onSearchChanged,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Where are you going?',
                          hintStyle: GoogleFonts.outfit(
                            color: Colors.grey.withOpacity(0.8),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (mapProvider.searchController.text.isNotEmpty || mapProvider.isSearchExpanded)
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded, 
                          color: isDark ? Colors.white60 : Colors.black45,
                          size: 20,
                        ),
                        onPressed: () {
                          mapProvider.toggleSearch(false);
                          _focusNode.unfocus();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Suggestions List with Smooth Appearance
          if (mapProvider.isSearchExpanded && mapProvider.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: mapProvider.suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1, 
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      indent: 60,
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = mapProvider.suggestions[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.blue, size: 20),
                        ),
                        title: Text(
                          suggestion['place_name'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: suggestion['context'] != null ? Text(
                          (suggestion['context'] as List).map((c) => c['text']).join(', '),
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ) : null,
                        onTap: () {
                          mapProvider.selectSuggestion(suggestion);
                          _focusNode.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
