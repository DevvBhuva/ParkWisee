import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parkwise/core/theme/app_theme.dart';
import 'package:parkwise/features/auth/screens/welcome_screen.dart';
import 'package:parkwise/features/home/screens/home_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parkwise/features/notifications/services/local_notification_service.dart';

import 'package:parkwise/features/notifications/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    // For Android, this will automatically use the google-services.json file
    // that we added to android/app/
    await Firebase.initializeApp();

    // Initialize System Notifications
    await LocalNotificationService().initialize();

    // Initialize FCM
    await FCMService().initialize();
  } catch (e) {
    debugPrint("Firebase/Notification Initialization failed: $e");
  }

  // Check if user is already logged in
  Widget initialScreen = const WelcomeScreen();
  if (FirebaseAuth.instance.currentUser != null) {
    initialScreen = const HomeScreen();
  }

  runApp(ParkWiseApp(initialScreen: initialScreen));
}

class ParkWiseApp extends StatelessWidget {
  final Widget initialScreen;
  const ParkWiseApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
    );
  }
}
