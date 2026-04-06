import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkwise/features/navigation/providers/map_provider.dart';

class MapControls extends StatelessWidget {
  const MapControls({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelectionVisible = mapProvider.selectedLocation != null || mapProvider.selectedParkingSpot != null;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      bottom: isSelectionVisible ? 420 : 112, // Increased from 24 to 112 (82 navbar + 30 spacing)
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom In
          _ControlButton(
            icon: Icons.add,
            onPressed: mapProvider.zoomIn,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          
          // Zoom Out
          _ControlButton(
            icon: Icons.remove,
            onPressed: mapProvider.zoomOut,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Re-center
          FloatingActionButton(
            heroTag: "recenter_btn",
            onPressed: mapProvider.centerOnUser,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            foregroundColor: Colors.blue,
            shape: const CircleBorder(),
            elevation: 8,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
        ),
      ),
    );
  }
}
