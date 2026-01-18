import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign Up with Email & Password
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Email & Password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign In aborted by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Facebook
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Trigger the authentication flow
      // Note: Requires flutter_facebook_auth package and configuration
      // For this implementation using Firebase Auth provider directly if possible
      // or returning standard error for setup

      // Placeholder for Facebook Auth
      throw Exception(
        "Facebook Sign In requires 'flutter_facebook_auth' package and App ID configuration.",
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Microsoft
  Future<UserCredential> signInWithMicrosoft() async {
    try {
      // Create a new provider
      final MicrosoftAuthProvider microsoftProvider = MicrosoftAuthProvider();
      // Once signed in, return the UserCredential
      // Note: This often requires web-based flow or specific package on mobile
      return await _auth.signInWithProvider(microsoftProvider);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Helper to handle exceptions nicely
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password provided is too weak.';
        default:
          return e.message ?? 'An unknown authentication error occurred.';
      }
    }
    return e.toString();
  }
}
