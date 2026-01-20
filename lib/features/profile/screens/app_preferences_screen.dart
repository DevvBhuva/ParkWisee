import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  // Dummy preferences
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _biometricAuth = false;
  ThemeMode _themeMode = ThemeMode.system; // Local state only

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Use a StatefulBuilder to update the sheet UI when selection changes
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Theme',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildThemeOption(
                    context,
                    ThemeMode.light,
                    'Light Mode',
                    Icons.light_mode,
                    setSheetState,
                  ),
                  _buildThemeOption(
                    context,
                    ThemeMode.dark,
                    'Dark Mode',
                    Icons.dark_mode,
                    setSheetState,
                  ),
                  _buildThemeOption(
                    context,
                    ThemeMode.system,
                    'System Default',
                    Icons.settings_brightness,
                    setSheetState,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String title,
    IconData icon,
    StateSetter setSheetState,
  ) {
    final isSelected = _themeMode == mode;

    return GestureDetector(
      onTap: () {
        // Update local state to show selection, but don't change app theme
        setState(() {
          _themeMode = mode;
        });
        setSheetState(() {}); // Update the bottom sheet

        // Show "Coming Soon" message if not Light
        if (mode == ThemeMode.dark || mode == ThemeMode.system) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$title is coming soon! Keeping light mode for now.',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: Colors.black,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Close the sheet after a short delay or immediately
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const isDark = false; // Forced light mode
    const textColor = Colors.black;
    final subTextColor = Colors.grey.shade500;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'App Preferences',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSectionHeader('NOTIFICATIONS'),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive parking alerts & offers',
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
              textColor: textColor,
              subTextColor: subTextColor,
              isDark: isDark,
            ),
            _buildSwitchTile(
              title: 'Email Updates',
              subtitle: 'Weekly summary & promotions',
              value: _emailUpdates,
              onChanged: (v) => setState(() => _emailUpdates = v),
              textColor: textColor,
              subTextColor: subTextColor,
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('APPEARANCE'),
            _buildSelectionTile(
              title: 'App Theme',
              subtitle: _getThemeName(_themeMode),
              icon: Icons.brightness_6_outlined,
              onTap: () => _showThemeSelector(context),
              textColor: textColor,
              subTextColor: subTextColor,
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('SECURITY'),
            _buildSwitchTile(
              title: 'Biometric Authentication',
              subtitle: 'Use FaceID/Fingerprint to login',
              value: _biometricAuth,
              onChanged: (v) => setState(() => _biometricAuth = v),
              textColor: textColor,
              subTextColor: subTextColor,
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('DATA & STORAGE'),
            _buildActionTile(
              title: 'Clear Cache',
              subtitle: 'Free up local storage space',
              icon: Icons.cleaning_services_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              },
              textColor: textColor,
              subTextColor: subTextColor,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.outfit(fontSize: 12, color: subTextColor),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
