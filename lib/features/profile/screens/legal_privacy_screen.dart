import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LegalPrivacyScreen extends StatelessWidget {
  const LegalPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Legal & Privacy',
          style: GoogleFonts.outfit(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Terms of Service',
              'Welcome to ParkWise. By using our app, you agree to these terms. Please read them carefully. We provide a platform to connect drivers with parking spot owners. We are not responsible for any damage to vehicles or loss of property.',
              textColor,
              subTextColor,
            ),
            const Divider(height: 48),
            _buildSection(
              'Privacy Policy',
              'Your privacy is important to us. We collect personal information such as your name, email, and vehicle details to provide our services. We do not sell your data to third parties. We use industry-standard security measures to protect your information.',
              textColor,
              subTextColor,
            ),
            const Divider(height: 48),
            _buildSection(
              'Data Usage',
              'We use your location booking data to improve our parking algorithms and provide better suggestions. All data is anonymized where possible.',
              textColor,
              subTextColor,
            ),
            const Divider(height: 48),
            _buildSection(
              'Refund Policy',
              'Refunds are processed within 5-7 business days for eligible cancellations. Please refer to our FAQ for cancellation rules.',
              textColor,
              subTextColor,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.outfit(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    Color titleColor,
    Color contentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: contentColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
