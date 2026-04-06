import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parkwise/core/theme/app_theme.dart';
import 'package:parkwise/features/auth/screens/welcome_screen.dart';
import 'package:parkwise/features/home/screens/home_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parkwise/core/theme/theme_provider.dart';
import 'package:parkwise/features/notifications/services/local_notification_service.dart';
import 'package:parkwise/features/navigation/providers/map_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    // For Android, this will automatically use the google-services.json file
    // that we added to android/app/
    await Firebase.initializeApp();

    // Initialize System Notifications
    await LocalNotificationService().initialize();

    // Set Mapbox Access Token Globally (v2.18.0+)
    String mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    MapboxOptions.setAccessToken(mapboxToken);
  } catch (e) {
    debugPrint("Firebase/Notification/Mapbox Initialization failed: $e");
  }

  // Initialize SharedPreferences for Theme Persistence
  final prefs = await SharedPreferences.getInstance();



  // Check if user is already logged in
  Widget initialScreen = const WelcomeScreen();
  if (FirebaseAuth.instance.currentUser != null) {
    initialScreen = const HomeScreen();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: ParkWiseApp(initialScreen: initialScreen),
    ),
  );
}



class ParkWiseApp extends StatelessWidget {
  final Widget initialScreen;
  const ParkWiseApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ParkWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        final bool isDark = themeProvider.themeMode == ThemeMode.dark || 
                          (themeProvider.themeMode == ThemeMode.system && brightness == Brightness.dark);

        return AnimatedTheme(
          data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: child!,
        );
      },
      home: initialScreen,
    );
  }

}

