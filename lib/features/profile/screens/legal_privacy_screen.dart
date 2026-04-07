import 'package:flutter/material.dart';

class LegalPrivacyScreen extends StatelessWidget {
  const LegalPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Legal & Privacy',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Terms of Service',
              'Welcome to ParkWise. By using our app, you agree to these terms. Please read them carefully. We provide a platform to connect drivers with parking spot owners. We are not responsible for any damage to vehicles or loss of property.',
              colorScheme.onSurface,
              colorScheme.onSurfaceVariant,
            ),
            const Divider(height: 48),
            _buildSection(
              context,
              'Privacy Policy',
              'Your privacy is important to us. We collect personal information such as your name, email, and vehicle details to provide our services. We do not sell your data to third parties. We use industry-standard security measures to protect your information.',
              colorScheme.onSurface,
              colorScheme.onSurfaceVariant,
            ),
            const Divider(height: 48),
            _buildSection(
              context,
              'Data Usage',
              'We use your location booking data to improve our parking algorithms and provide better suggestions. All data is anonymized where possible.',
              colorScheme.onSurface,
              colorScheme.onSurfaceVariant,
            ),
            const Divider(height: 48),
            _buildSection(
              context,
              'Refund Policy',
              'Refunds are processed within 5-7 business days for eligible cancellations. Please refer to our FAQ for cancellation rules.',
              colorScheme.onSurface,
              colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: contentColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
