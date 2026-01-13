import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _getUserDoc() {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(_userId);
  }

  // Stream of user profile data
  Stream<Map<String, dynamic>?> getUserStream() {
    if (_userId == null) return Stream.value(null);
    return _getUserDoc().snapshots().map((snapshot) => snapshot.data());
  }

  // Create Profile if it doesn't exist (e.g., on first login/migrating)
  Future<void> createProfileIfNew() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _getUserDoc();
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update Profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _getUserDoc().set(updates, SetOptions(merge: true));
      debugPrint("User Profile updated in Firestore");

      // Also try to update Auth profile for consistency (Display Name)
      if (name != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name);
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    }
  }
}
