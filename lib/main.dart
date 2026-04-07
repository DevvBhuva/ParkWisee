import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parkwise/core/theme/app_theme.dart';
import 'package:parkwise/features/auth/screens/welcome_screen.dart';
import 'package:parkwise/features/home/screens/home_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parkwise/features/notifications/services/local_notification_service.dart';
import 'package:parkwise/features/navigation/providers/map_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Get saved theme mode
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  try {
    await Firebase.initializeApp();

    // Initialize System Notifications
    await LocalNotificationService().initialize();

    // Set Mapbox Access Token Globally (v2.18.0+)
    String mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    MapboxOptions.setAccessToken(mapboxToken);
  } catch (e) {
    debugPrint("Firebase/Notification/Mapbox Initialization failed: $e");
  }

  // Check if user is already logged in
  Widget initialScreen = const WelcomeScreen();
  if (FirebaseAuth.instance.currentUser != null) {
    initialScreen = const HomeScreen();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: ParkWiseApp(
        initialScreen: initialScreen,
        savedThemeMode: savedThemeMode,
      ),
    ),
  );
}

class ParkWiseApp extends StatelessWidget {
  final Widget initialScreen;
  final AdaptiveThemeMode? savedThemeMode;

  const ParkWiseApp({
    super.key, 
    required this.initialScreen,
    this.savedThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: AppTheme.lightTheme,
      dark: AppTheme.darkTheme,
      initial: savedThemeMode ?? AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'ParkWise',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        home: initialScreen,
      ),
    );
  }
}

