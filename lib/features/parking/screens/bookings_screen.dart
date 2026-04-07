import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';
import 'package:parkwise/features/parking/services/local_booking_service.dart';
import 'package:parkwise/features/parking/widgets/booking_item_card.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  final BookingFirestoreService _bookingService = BookingFirestoreService();
  final LocalBookingService _localBookingService = LocalBookingService();
  List<Booking> _localBookings = [];
  StreamSubscription? _localUpdateSubscription;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocalBookings();
    _localUpdateSubscription = _localBookingService.onBookingUpdated.listen((_) {
      _loadLocalBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Expired'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingService.getBookingsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _localBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final firestoreBookings =
              snapshot.hasData ? snapshot.data! : <Booking>[];

          if (snapshot.hasError) {
            debugPrint('Error fetching remote bookings: ${snapshot.error}');
          }

          final allBookingsMap = {
            for (var b in _localBookings) b.id: b,
            for (var b in firestoreBookings) b.id: b,
          };

          final bookings = allBookingsMap.values.toList();
          bookings.sort((a, b) => b.startTime.compareTo(a.startTime));

          final now = DateTime.now();
          final activeBookings =
              bookings.where((b) => b.endTime.isAfter(now)).toList();
          final expiredBookings =
              bookings.where((b) => !b.endTime.isAfter(now)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(activeBookings, isActive: true),
              _buildBookingList(expiredBookings, isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, {required bool isActive}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.directions_car_outlined : Icons.history,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active bookings' : 'No past bookings',
              style: GoogleFonts.outfit(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Your current bookings will appear here'
                  : 'Your booking history will appear here',
              style: GoogleFonts.outfit(
                color: colorScheme.outlineVariant,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 200 + index * 60),
          child: BookingItemCard(booking: bookings[index]),
        );
      },
    );
  }
}
