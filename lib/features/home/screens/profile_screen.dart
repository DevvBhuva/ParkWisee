import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/auth/services/auth_service.dart';
import 'package:parkwise/features/auth/screens/login_screen.dart';
import 'package:parkwise/features/profile/screens/my_vehicles_screen.dart';
import 'package:parkwise/features/profile/screens/payment_methods_screen.dart';
import 'package:parkwise/features/profile/screens/saved_locations_screen.dart';
import 'package:parkwise/features/profile/widgets/export_history_dialog.dart';
import 'package:parkwise/features/profile/services/user_firestore_service.dart';
import 'package:parkwise/features/profile/screens/app_preferences_screen.dart';
import 'package:parkwise/features/profile/screens/help_support_screen.dart';
import 'package:parkwise/features/profile/screens/legal_privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserFirestoreService _firestoreService = UserFirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isExpanded = false;
  bool _isModified = false;

  // Data snapshots to compare against
  String _currentName = '';
  String _currentEmail = '';
  String _currentPhone = '';

  @override
  void initState() {
    super.initState();
    // Initialize with empty, will populate from Stream
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _nameController.addListener(_checkModified);
    _emailController.addListener(_checkModified);
    _phoneController.addListener(_checkModified);

    // Ensure profile document exists
    _firestoreService.createProfileIfNew();
  }

  void _checkModified() {
    final isModified =
        _nameController.text != _currentName ||
        _emailController.text != _currentEmail ||
        _phoneController.text != _currentPhone;

    if (isModified != _isModified) {
      setState(() {
        _isModified = isModified;
      });
    }
  }

  void _updateControllers(Map<String, dynamic> data) {
    // Only update controllers if we are NOT expanded (syncing)
    // or if the values are empty (initial load).
    // This prevents overwriting user input while they type if a background update happens.
    // However, for this simple app, we can just update when the stream emits if not modified.

    final newName = data['name'] as String? ?? '';
    final newEmail = data['email'] as String? ?? '';
    final newPhone = data['phone'] as String? ?? '';

    if (_currentName != newName ||
        _currentEmail != newEmail ||
        _currentPhone != newPhone) {
      if (!_isModified) {
        _nameController.text = newName;
        _emailController.text = newEmail;
        _phoneController.text = newPhone;
      }

      setState(() {
        _currentName = newName;
        _currentEmail = newEmail;
        _currentPhone = newPhone;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      // If closing, reset to saved values (cancel edits)
      if (!_isExpanded && _isModified) {
        _nameController.text = _currentName;
        _emailController.text = _currentEmail;
        _phoneController.text = _currentPhone;
        _isModified = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final shadowColor = isDark
        ? Colors.transparent
        : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.getUserStream(),
        builder: (context, snapshot) {
          // Update local state if data exists
          if (snapshot.hasData && snapshot.data != null) {
            // Use addPostFrameCallback to avoid updating state during build if needed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateControllers(snapshot.data!);
            });
          } else if (snapshot.connectionState == ConnectionState.active &&
              snapshot.data == null) {
            // No data yet, maybe just created. Use Auth defaults.
            final user = _authService.currentUser;
            if (user != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateControllers({
                  'name': user.displayName,
                  'email': user.email,
                  'phone': user.phoneNumber,
                });
              });
            }
          }

          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 120,
              ),
              child: Column(
                children: [
                  // Standard Header Title
                  Center(
                    child: Text(
                      'Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Expandable Profile Card Header
                  GestureDetector(
                    onTap: _toggleExpanded,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Profile Icon
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade50,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(3),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/profile_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentName.isNotEmpty
                                          ? _currentName
                                          : 'User Name',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to view & edit details',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          // Expandable Content
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Name',
                                    icon: Icons.person_outline,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 24),
                                  // Update Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isModified
                                          ? () async {
                                              try {
                                                await _firestoreService
                                                    .updateProfile(
                                                      name:
                                                          _nameController.text,
                                                      email:
                                                          _emailController.text,
                                                      phone:
                                                          _phoneController.text,
                                                    );

                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Profile Updated Successfully',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                  setState(() {
                                                    _isModified = false;
                                                  });
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error updating profile: $e',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          69,
                                          255,
                                          66,
                                        ),
                                        disabledBackgroundColor: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade300,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Update',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: _isModified
                                              ? Colors.black
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            crossFadeState: _isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Settings List
                  _buildMenuItem(
                    iconPath: 'assets/images/my_vehicle_logo.png',
                    title: 'My Vehicles',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyVehiclesScreen(),
                      ),
                    ),
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    iconPath: 'assets/images/payment_method_logo.png',
                    title: 'Saved Payment Methods',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentMethodsScreen(),
                      ),
                    ),
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    iconPath: 'assets/images/location_logo.png',
                    title: 'Saved Locations',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedLocationsScreen(),
                      ),
                    ),
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    iconPath: 'assets/images/export_parking_logo.png',
                    title: 'Export Parking History',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ExportHistoryDialog(),
                      );
                    },
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    iconPath: 'assets/images/app_preferences_logo.png',
                    title: 'App Preferences',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppPreferencesScreen(),
                      ),
                    ),
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    iconPath: 'assets/images/help_&_support_logo.png',
                    title: 'Help & Support',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    ),
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    iconPath: 'assets/images/legal_&_privacy_logo.png',
                    title: 'Legal & Privacy',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LegalPrivacyScreen(),
                      ),
                    ),
                    textColor: textColor,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _authService.signOut();
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'LOGOUT',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
          borderSide: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    required Color textColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            ColorFiltered(
              colorFilter: isDark
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.asset(
                iconPath,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
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
}
