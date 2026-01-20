import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';
import 'package:parkwise/features/profile/services/payment_firestore_service.dart';
import 'package:parkwise/features/parking/screens/ticket_screen.dart';
import 'package:parkwise/features/home/widgets/slide_to_book_button.dart';
import 'package:parkwise/features/parking/models/booking_model.dart';
import 'package:parkwise/features/parking/services/booking_firestore_service.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkwise/features/parking/services/local_booking_service.dart';
import 'package:parkwise/features/notifications/services/notification_service.dart';
import 'package:parkwise/features/notifications/models/notification_model.dart';
import 'package:parkwise/features/parking/services/cashfree_service.dart'; // Added
import 'dart:convert';

class BookingSummaryScreen extends StatefulWidget {
  final ParkingSpot spot;
  final int slotId;
  final DateTime startTime;
  final double duration;
  final double totalPrice;
  final String vehicleModel;
  final String licensePlate;
  final double hourlyRate;
  final String vehicleType; // Added: 'car', 'bike', etc.

  const BookingSummaryScreen({
    Key? key,
    required this.spot,
    required this.slotId,
    required this.startTime,
    required this.duration,
    required this.totalPrice,
    required this.vehicleModel,
    required this.licensePlate,
    required this.hourlyRate,
    required this.vehicleType,
  }) : super(key: key);

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final PaymentFirestoreService _paymentService = PaymentFirestoreService();
  final BookingFirestoreService _bookingService = BookingFirestoreService();
  final LocalBookingService _localBookingService = LocalBookingService();

  // Special object for Cashfree
  final PaymentMethod _cashfreeMethod = PaymentMethod(
    id: 'cashfree_gateway',
    category: 'Cashfree',
    type: 'GATEWAY',
    maskedNumber: 'UPI / Cards / NetBanking',
  );

  PaymentMethod? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = _cashfreeMethod;
  }

  /// Handles the actual creation of booking in Firestore after payment or if saved card used.
  Future<void> _processBooking(String paymentId, String paymentType) async {
    print('>>> STARTING BOOKING PROCESS: $paymentId');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to book')));
      return;
    }

    final bookingId = const Uuid().v4();
    final qrDataMap = {
      'bid': bookingId,
      'sid': widget.spot.id,
      'slot': widget.slotId + 1,
      'veh': widget.licensePlate,
      'time': widget.startTime.toIso8601String(),
    };
    final qrDataJson = jsonEncode(qrDataMap);

    final newBooking = Booking(
      id: bookingId,
      userId: user.uid,
      parkingSpotId: widget.spot.id,
      spotName: widget.spot.name,
      spotAddress: widget.spot.address,
      slotId: widget.slotId,
      vehicleId: widget.vehicleType,
      vehicleModel: widget.vehicleModel,
      vehicleNumber: widget.licensePlate,
      startTime: widget.startTime,
      endTime: widget.startTime.add(
        Duration(minutes: (widget.duration * 60).toInt()),
      ),
      totalPrice: widget.totalPrice,
      status: 'confirmed',
      createdAt: DateTime.now(),
      qrData: qrDataJson,
      paymentMethodId: paymentId,
      paymentMethodType: paymentType,
    );

    try {
      await _bookingService.createBooking(newBooking);
      // Create Notification
      try {
        await NotificationService().createNotification(
          title: 'Parking Confirmed',
          body: 'Your slot at ${widget.spot.name} is reserved.',
          type: NotificationType.confirmation,
          relatedBookingId: newBooking.id,
        );
      } catch (e) {
        debugPrint('Notif Error: $e');
      }
    } catch (e) {
      print('>>> CRITICAL BOOKING ERROR: $e');
      print('>>> Saving locally as fallback...');
      await _localBookingService.saveBooking(newBooking);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketScreen(booking: newBooking),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
  }

  String _formatDuration(double val) {
    int hours = val.floor();
    int minutes = ((val - hours) * 60).round();
    if (minutes == 60) {
      hours++;
      minutes = 0;
    }
    String label = '${hours}hr';
    if (minutes > 0) label += ' ${minutes}min';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Summary',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Parking Spot Details
            _buildSectionHeader('Parking Details'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.spot.name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.spot.address,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Slot P${widget.slotId + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    'Start Time',
                    _formatDateTime(widget.startTime),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Duration', _formatDuration(widget.duration)),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Vehicle',
                    '${widget.vehicleModel} (${widget.licensePlate})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Pricing
            _buildSectionHeader('Payment Breakdown'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildInfoRow('Rate', '\u20B9${widget.hourlyRate}/hr'),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total to Pay',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\u20B9${widget.totalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Payment Methods
            _buildSectionHeader('Select Payment Method'),

            StreamBuilder<List<PaymentMethod>>(
              stream: _paymentService.getPaymentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Combine explicit Cashfree option with saved methods
                final methods = [_cashfreeMethod, ...(snapshot.data ?? [])];

                return Column(
                  children: [
                    ...methods.map((method) {
                      final isSelected =
                          _selectedPaymentMethod?.id == method.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPaymentMethod = method);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              if (method.id == 'cashfree_gateway')
                                Image.asset(
                                  'assets/images/cashfree_logo.png',
                                  width: 32, // Adjust size as needed
                                  height: 32,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.payment,
                                    color: Colors.purple,
                                  ),
                                )
                              else
                                Icon(
                                  method.type == 'GATEWAY'
                                      ? Icons.payment
                                      : (method.type == 'UPI'
                                            ? Icons.qr_code
                                            : Icons.credit_card),
                                  color: Colors.black87,
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.category,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (method.maskedNumber.isNotEmpty)
                                      Text(
                                        method.maskedNumber,
                                        style: GoogleFonts.outfit(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    if (method.upiId != null &&
                                        method.upiId!.isNotEmpty)
                                      Text(
                                        method.upiId!,
                                        style: GoogleFonts.outfit(
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    // Add New Method Option (Simple visual for now)
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Manage Payments in Profile'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              'Add Payment Method',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 100), // Spacing for fab
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: _selectedPaymentMethod == null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Select Payment Method',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : SlideToBookButton(
                    label:
                        'Slide to Pay \u20B9${widget.totalPrice.toStringAsFixed(0)}',
                    completionLabel: 'Processing...',
                    onCompleted: () async {
                      if (_selectedPaymentMethod == null) return;

                      // 1. If Cashfree Gateway
                      if (_selectedPaymentMethod!.id == 'cashfree_gateway') {
                        final user = FirebaseAuth.instance.currentUser;
                        final orderId =
                            "ORDER_${DateTime.now().millisecondsSinceEpoch}";

                        print(">>> Initiating Cashfree Payment: $orderId");

                        // Fallback values
                        String phone = "+919999999999";
                        if (user?.phoneNumber != null &&
                            user!.phoneNumber!.isNotEmpty) {
                          phone = user.phoneNumber!;
                        }

                        await CashfreeService().doPayment(
                          orderId: orderId,
                          amount: widget.totalPrice,
                          customerPhone: phone,
                          customerEmail: user?.email ?? "guest@parkwise.com",
                          userId:
                              user?.uid ?? const Uuid().v4(), // Safe fallback
                          onVerify: (verifiedOrderId) {
                            print(">>> Payment Verified: $verifiedOrderId");
                            _processBooking(verifiedOrderId, 'CASHFREE');
                          },
                          onError: (error, id) {
                            print(">>> Payment Failed: $error");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Payment Failed: $error')),
                            );
                          },
                        );
                      } else {
                        // 2. Offline/Saved Method
                        await _processBooking(
                          _selectedPaymentMethod!.id,
                          _selectedPaymentMethod!.type,
                        );
                      }
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.grey.shade600)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
