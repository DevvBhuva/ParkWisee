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
  const BookingsScreen({Key? key}) : super(key: key);

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
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view bookings')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Bookings',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingService.getBookingsStream(user.uid),
        builder: (context, snapshot) {
          // If waiting and no local bookings, show loader.
          // If we have local bookings, we can show them while loading remote.
          if (snapshot.connectionState == ConnectionState.waiting &&
              _localBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gather remote bookings if available, ignoring errors to prioritize availability
          final firestoreBookings = snapshot.hasData
              ? snapshot.data!
              : <Booking>[];

          if (snapshot.hasError) {
            debugPrint('Error fetching remote bookings: ${snapshot.error}');
          }

          // Merge and Deduplicate
          final allBookingsMap = {
            for (var b in _localBookings) b.id: b, // Local first
            for (var b in firestoreBookings)
              b.id: b, // Remote overrides (if exists)
          };

          final bookings = allBookingsMap.values.toList();

          // Sort by start time descending (newest first)
          bookings.sort((a, b) => b.startTime.compareTo(a.startTime));

          return _buildBookingList(bookings);
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: GoogleFonts.outfit(color: Colors.grey),
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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketScreen(booking: booking),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isExpired ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isExpired
                  ? Border.all(color: Colors.grey.shade300)
                  : null,
              boxShadow: isExpired
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey.shade200
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_parking,
                    color: isExpired ? Colors.grey : Colors.green,
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
                          color: isExpired
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM d, h:mm a').format(booking.startTime)}',
                        style: GoogleFonts.outfit(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\u20B9${booking.totalPrice.toStringAsFixed(0)} • ${booking.vehicleNumber}',
                        style: GoogleFonts.outfit(
                          color: isExpired ? Colors.grey : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isExpired
                      ? Colors.grey.shade300
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
