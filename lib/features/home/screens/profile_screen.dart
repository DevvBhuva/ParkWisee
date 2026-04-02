import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:parkwise/features/auth/services/auth_service.dart';

import 'package:parkwise/features/profile/services/user_firestore_service.dart';
import 'package:parkwise/features/profile/screens/my_vehicles_screen.dart';
import 'package:parkwise/features/profile/screens/payment_methods_screen.dart';
import 'package:parkwise/features/profile/screens/saved_locations_screen.dart';
import 'package:parkwise/features/profile/screens/app_preferences_screen.dart';
import 'package:parkwise/features/profile/screens/help_support_screen.dart';
import 'package:parkwise/features/profile/screens/legal_privacy_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/auth/screens/login_screen.dart';
import 'package:parkwise/features/profile/widgets/export_history_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserFirestoreService _firestoreService = UserFirestoreService();
  String _userName = 'User Name';
  String _userPhone = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    // Try to get from Firestore first, fallback to Auth
    try {
      final userDoc = await _firestoreService.getUserStream().first;
      if (userDoc != null) {
        if (mounted) {
          setState(() {
            _userName = userDoc['name'] ?? 'User Name';
            _userPhone = userDoc['phone'] ?? '';
            _nameController.text = _userName;
            _phoneController.text = _userPhone;
          });
        }
      } else {
        final user = _authService.currentUser;
        if (user != null && mounted) {
          setState(() {
            _userName = user.displayName ?? 'User Name';
            _userPhone = user.phoneNumber ?? '';
            _nameController.text = _userName;
            _phoneController.text = _userPhone;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _userName = _nameController.text.trim();
          _userPhone = _phoneController.text.trim();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: 120.0, // Increased bottom padding to clear the floating nav
          ),
          children: [
            const SizedBox(height: 20),
            // Profile Header (Expandable)
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  childrenPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/profile_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _userName,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Tap to edit details',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: GoogleFonts.outfit(
                          color: Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Colors.grey.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      style: GoogleFonts.outfit(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        labelStyle: GoogleFonts.outfit(
                          color: Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: Colors.grey.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildMenuItem(
              context,
              assetPath: 'assets/images/my_vehicle_logo.png',
              title: 'My Vehicles',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyVehiclesScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              assetPath: 'assets/images/payment_method_logo.png',
              title: 'Payment Methods',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentMethodsScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              assetPath: 'assets/images/location_logo.png',
              title: 'Saved Locations',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedLocationsScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              assetPath: 'assets/images/export_parking_logo.png',
              title: 'Export Parking History',
              onTap: () => showDialog(
                context: context,
                builder: (context) => const ExportHistoryDialog(),
              ),
            ),
            _buildMenuItem(
              context,
              assetPath: 'assets/images/app_preferences_logo.png',
              title: 'App Preferences',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppPreferencesScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              assetPath: 'assets/images/help_&_support_logo.png',
              title: 'Help & Support',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              assetPath: 'assets/images/legal_&_privacy_logo.png',
              title: 'Legal & Privacy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalPrivacyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String assetPath,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            assetPath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
