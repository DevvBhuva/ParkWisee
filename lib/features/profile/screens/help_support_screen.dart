import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Help & Support',
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
          children: [
            // Contact Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.headset_mic,
                    color: isDark ? Colors.black : Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Need help?',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our team is here to assist you.',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.grey.shade800 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildContactRow(
                    Icons.email,
                    'support@parkwise.com',
                    isDark ? Colors.black : Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(
                    Icons.phone,
                    '+1 (800) 123-4567',
                    isDark ? Colors.black : Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FAQs
            _buildFaqItem(
              'How do I book a parking spot?',
              'Navigate to the home screen, select a spot on the map, choose your duration, and proceed to payment.',
              cardColor,
              borderColor,
              textColor,
              subTextColor,
            ),
            _buildFaqItem(
              'Can I cancel my booking?',
              'Yes, bookings can be canceled up to 15 minutes before the start time for a full refund.',
              cardColor,
              borderColor,
              textColor,
              subTextColor,
            ),
            _buildFaqItem(
              'What payment methods are supported?',
              'We support all major Credit/Debit cards and UPI payments like GPay and PhonePe.',
              cardColor,
              borderColor,
              textColor,
              subTextColor,
            ),
            _buildFaqItem(
              'How do I add my vehicle?',
              'Go to Profile > My Vehicles and tap the "+" button to add your vehicle details.',
              cardColor,
              borderColor,
              textColor,
              subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFaqItem(
    String question,
    String answer,
    Color bg,
    Color border,
    Color text,
    Color subText,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: text,
          collapsedIconColor: text,
          title: Text(
            question,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: text),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.outfit(color: subText, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
