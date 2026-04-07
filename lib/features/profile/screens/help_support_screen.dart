import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Contact Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary, // Dark card in both modes, or primary
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.headset_mic,
                    color: colorScheme.onPrimary,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Need help?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our team is here to assist you.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildContactRow(
                    context,
                    Icons.email,
                    'support@parkwise.com',
                    colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(
                    context,
                    Icons.phone,
                    '+1 (800) 123-4567',
                    colorScheme.onPrimary,
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FAQs
            _buildFaqItem(
              context,
              'How do I book a parking spot?',
              'Navigate to the home screen, select a spot on the map, choose your duration, and proceed to payment.',
              colorScheme,
            ),
            _buildFaqItem(
              context,
              'Can I cancel my booking?',
              'Yes, bookings can be canceled up to 15 minutes before the start time for a full refund.',
              colorScheme,
            ),
            _buildFaqItem(
              context,
              'What payment methods are supported?',
              'We support all major Credit/Debit cards and UPI payments like GPay and PhonePe.',
              colorScheme,
            ),
            _buildFaqItem(
              context,
              'How do I add my vehicle?',
              'Go to Profile > My Vehicles and tap the "+" button to add your vehicle details.',
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    String question,
    String answer,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: colorScheme.onSurface,
          collapsedIconColor: colorScheme.onSurface,
          title: Text(
            question,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
