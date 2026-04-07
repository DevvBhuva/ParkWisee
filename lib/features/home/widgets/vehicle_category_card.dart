import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/core/widgets/tap_animation.dart';

class VehicleCategoryCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleCategoryCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TapAnimation(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.secondary : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? colorScheme.secondary : colorScheme.outline,
              ),
              boxShadow: (isSelected || isDark)
                  ? null
                  : [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              color: isSelected ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
