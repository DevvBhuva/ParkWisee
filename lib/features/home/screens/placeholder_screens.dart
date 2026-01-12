import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'My Bookings',
        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Navigation',
        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
