import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:parkwise/features/navigation/providers/map_provider.dart';

class LocationDetailsSheet extends StatelessWidget {
  const LocationDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isVisible = mapProvider.selectedLocation != null || mapProvider.selectedParkingSpot != null;
    
    if (!isVisible) return const SizedBox.shrink();

    final String name = mapProvider.selectedParkingSpot?.name ?? 
                        mapProvider.selectedLocation?['place_name']?.split(',')[0] ?? 
                        "Selected Location";
    final String address = mapProvider.selectedParkingSpot?.address ?? 
                           mapProvider.selectedLocation?['place_name'] ?? 
                           "";

    return DraggableScrollableSheet(
      controller: mapProvider.sheetController,
      initialChildSize: 0.32,
      minChildSize: 0.24,
      maxChildSize: 0.8,
      snap: true,
      snapSizes: const [0.24, 0.32, 0.8],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Scrollable Content
              ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.paddingOf(context).bottom + 180), // Extra padding for button + navbar
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title & Close
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey.withOpacity(0.9),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: mapProvider.clearSelection,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Trip Details Info (Distance/Time)
                  if (mapProvider.isFetchingRoute)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (mapProvider.routeDuration != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.blue.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_car_rounded, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${mapProvider.routeDuration} • ${mapProvider.routeDistance}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Fastest route with current traffic",
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  
                  // Content padding for future details
                  const SizedBox(height: 100),
                ],
              ),

              // Sticky "Start Navigation" Button
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + 106, // Clear Floating Navbar (82) + spacing (24)
                left: 24,
                right: 24,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Navigation started!"),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 8, // Added elevation as requested
                      shadowColor: Colors.blue.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_rounded),
                        const SizedBox(width: 12),
                        Text(
                          "Start Navigation",
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
