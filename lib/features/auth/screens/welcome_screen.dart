import 'package:flutter/material.dart';

import 'package:parkwise/features/auth/screens/login_screen.dart';
import 'package:parkwise/features/auth/screens/signup_screen.dart';
import 'package:parkwise/core/widgets/custom_background.dart';
import 'package:parkwise/core/widgets/page_animations.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomBackground(
        imagePath: 'assets/images/parking_aerial.jpg',
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo or Graphic With Hero Animation
              // Logo Removed as per user request
              const SizedBox(height: 18),
              Text(
                'ParkWise',
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Find and book parking slots instantly. Navigate with ease.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SlideUpRoute(page: SignupScreen()), // Removed const
                    );
                  },
                  child: const Text("Let's Get Started"),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already a customer?',
                    style: GoogleFonts.outfit(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, FadeRoute(page: LoginScreen()));
                    },
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
