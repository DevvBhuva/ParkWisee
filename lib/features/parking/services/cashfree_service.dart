import 'dart:convert';

import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CashfreeService {
  // Singleton
  static final CashfreeService _instance = CashfreeService._internal();
  factory CashfreeService() => _instance;
  CashfreeService._internal();

  final CFPaymentGatewayService _cfPaymentGatewayService =
      CFPaymentGatewayService();

  /// Creates an order in Cashfree (using Sandbox API) and initiates payment.
  ///
  /// [onVerify] is called when the payment is completed successfully by the SDK.
  /// [onError] is called when there is a failure.
  Future<void> doPayment({
    required String orderId,
    required double amount,
    required String customerPhone,
    required String customerEmail,
    required String userId, // Added
    required Function(String orderId) onVerify,
    required Function(String errorMsg, String orderId) onError,
  }) async {
    try {
      debugPrint("Creating order session for amount: $amount");
      // 1. Create Session ID from Backend (or here directly for testing)
      final sessionData = await _createOrderSession(
        orderId: orderId,
        amount: amount,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        userId: userId, // Pass it
      );

      debugPrint(">>> Cashfree API Response: $sessionData");

      final String paymentSessionId = sessionData['payment_session_id'];
      final String orderIdFromResponse = sessionData['order_id'];

      debugPrint('Session ID created: $paymentSessionId');
      debugPrint(
        ">>> Building CFSession with ID: $paymentSessionId, OrderID: $orderIdFromResponse",
      );

      // 2. Create CF Session
      var cfSession = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX)
          .setOrderId(orderIdFromResponse)
          .setPaymentSessionId(paymentSessionId)
          .build();

      debugPrint('Environment: SANDBOX');
      debugPrint('CF Session: $cfSession');
      debugPrint(">>> CFSession Built Successfully");

      // 3. Initiate Payment
      var cfWebCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(cfSession)
          .build();

      debugPrint('CF Payment: $cfWebCheckout');
      debugPrint(">>> CFWebCheckout Built Successfully. Setting Callback...");

      // 4. Set Callbacks
      _cfPaymentGatewayService.setCallback(
        (String orderId) {
          debugPrint('Payment Verified: $orderId');
          onVerify(orderId);
        },
        (CFErrorResponse errorResponse, String orderId) {
          debugPrint('Payment Failed/Error: ${errorResponse.getMessage()}');
          onError(errorResponse.getMessage() ?? "Unknown Error", orderId);
        },
      );

      debugPrint(">>> Invoking doPayment...");
      _cfPaymentGatewayService.doPayment(cfWebCheckout);
    } catch (e) {
      debugPrint("Cashfree Error: $e");
      onError("Session Creation Failed: $e", orderId);
    }
  }

  /// Calls Cashfree API to create an order and get payment_session_id.
  /// NOTE: IN PRODUCTION, THIS MUST BE DONE ON YOUR BACKEND SERVER.
  /// DO NOT EXPOSE YOUR SECRET KEY IN THE APP.
  Future<Map<String, dynamic>> _createOrderSession({
    required String orderId,
    required double amount,
    required String customerPhone,
    required String customerEmail,
    required String userId,
  }) async {
    final appId = dotenv.env['CASHFREE_APP_ID'];
    final secretKey = dotenv.env['CASHFREE_SECRET_KEY'];
    final apiVersion = "2022-09-01";

    if (appId == null || secretKey == null) {
      throw Exception(
        "CASHFREE_APP_ID or CASHFREE_SECRET_KEY not found in .env",
      );
    }

    const String url = "https://sandbox.cashfree.com/pg/orders";

    final headers = {
      'Content-Type': 'application/json',
      'x-client-id': appId,
      'x-client-secret': secretKey,
      'x-api-version': apiVersion,
    };

    final body = jsonEncode({
      "order_id": orderId,
      "order_amount": amount,
      "order_currency": "INR",
      "customer_details": {
        "customer_id": userId, // Use strict User ID
        "customer_name": "Parkwise User",
        "customer_email": customerEmail,
        "customer_phone": customerPhone
            .replaceAll('+91', '')
            .replaceAll('+', ''),
      },
      "order_meta": {
        "return_url": "https://example.com/return?order_id={order_id}",
      },
    });

    try {
      debugPrint(">>> Creating Cashfree Order: $url");
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint("Response Body: ${response.body}");
        return jsonDecode(response.body);
      } else {
        // Try to parse error message from body
        String errorMsg = "Status ${response.statusCode}";
        try {
          final errMap = jsonDecode(response.body);
          if (errMap['message'] != null) errorMsg = errMap['message'];
        } catch (_) {}
        throw Exception("API Error: $errorMsg");
      }
    } catch (e) {
      debugPrint("Cashfree Exception: $e");
      rethrow;
    }
  }
}
