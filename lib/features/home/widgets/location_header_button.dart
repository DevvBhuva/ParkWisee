import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationHeaderButton extends StatelessWidget {
  final String locationText;
  final VoidCallback onTap;

  const LocationHeaderButton({
    super.key,
    required this.locationText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: colorScheme.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              locationText,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
