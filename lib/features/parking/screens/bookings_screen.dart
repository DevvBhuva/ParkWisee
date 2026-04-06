import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';
import 'package:parkwise/features/parking/services/local_booking_service.dart';
import 'package:parkwise/features/parking/screens/ticket_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingFirestoreService _bookingService = BookingFirestoreService();
  final LocalBookingService _localBookingService = LocalBookingService();
  List<Booking> _localBookings = [];

  StreamSubscription? _localUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadLocalBookings();
    _localUpdateSubscription = _localBookingService.onBookingUpdated.listen((
      _,
    ) {
      _loadLocalBookings();
    });
  }

  @override
  void dispose() {
    _localUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLocalBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final local = await _localBookingService.getLocalBookings(user.uid);
      if (mounted) {
        setState(() {
          _localBookings = local;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Please login to view bookings',
            style: GoogleFonts.outfit(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Bookings',
          style: GoogleFonts.outfit(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingService.getBookingsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _localBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final firestoreBookings = snapshot.hasData ? snapshot.data! : <Booking>[];

          if (snapshot.hasError) {
            debugPrint('Error fetching remote bookings: ${snapshot.error}');
          }

          final allBookingsMap = {
            for (var b in _localBookings) b.id: b,
            for (var b in firestoreBookings) b.id: b,
          };

          final bookings = allBookingsMap.values.toList();
          bookings.sort((a, b) => b.startTime.compareTo(a.startTime));

          return _buildBookingList(bookings);
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings) {
    final colorScheme = Theme.of(context).colorScheme;
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: GoogleFonts.outfit(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final isExpired = booking.endTime.isBefore(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isExpired ? colorScheme.surfaceContainer.withValues(alpha: 0.5) : colorScheme.surfaceContainer,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketScreen(booking: booking),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isExpired ? colorScheme.surfaceContainerHighest : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_parking,
                      color: isExpired ? colorScheme.onSurfaceVariant : colorScheme.secondary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.spotName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isExpired ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, h:mm a').format(booking.startTime),
                          style: GoogleFonts.outfit(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${booking.endTime.difference(booking.startTime).inHours} hours',
                          style: GoogleFonts.outfit(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u20B9${booking.totalPrice.toStringAsFixed(0)} • ${booking.vehicleNumber}',
                          style: GoogleFonts.outfit(
                            color: isExpired ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
