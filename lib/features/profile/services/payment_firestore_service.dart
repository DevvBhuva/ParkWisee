import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';

class PaymentFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _getCollection() {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(_userId).collection('payments');
  }

  Stream<List<PaymentMethod>> getPaymentsStream() {
    if (_userId == null) return Stream.value([]);

    return _getCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id;
        return PaymentMethod.fromMap(map);
      }).toList();
    });
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    if (_userId == null) return;
    try {
      final docRef = _getCollection().doc();
      final newItem = PaymentMethod(
        id: docRef.id,
        category: method.category,
        type: method.type,
        maskedNumber: method.maskedNumber,
        expiryDate: method.expiryDate,
        cardHolderName: method.cardHolderName,
        upiId: method.upiId,
      );
      await docRef.set(newItem.toMap());
      debugPrint("Payment added: ${docRef.id}");
    } catch (e) {
      debugPrint("Error adding payment: $e");
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(PaymentMethod method) async {
    try {
      await _getCollection().doc(method.id).update(method.toMap());
    } catch (e) {
      debugPrint("Error updating payment: $e");
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await _getCollection().doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting payment: $e");
    }
  }
}
