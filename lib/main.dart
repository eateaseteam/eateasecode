import 'dart:io' show Platform;
import 'package:eatease_app_web/android_users/SplashScreen/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:timezone/data/latest.dart' as tz;
import 'Notification_Handler/notification_handler.dart';
import 'admin_page/welcome_screen/welcome_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with default options for the current platform
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Set persistence to local (to persist sessions across restarts)
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print('Firebase Auth persistence set to local');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Lock the app to portrait mode
  if (!kIsWeb) {
    // Avoid locking orientation on web
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style for dark mode
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFFEEEEEE), // Light gray background color to match the design
    statusBarIconBrightness: Brightness.dark, // Dark icons for better contrast on light background
    statusBarBrightness: Brightness.light, // For iOS compatibility (light status bar background)
  ));

  // Initialize time zones and notifications
  tz.initializeTimeZones();
  NotificationHandler notificationHandler = NotificationHandler();
  notificationHandler.initializeNotifications();

  // Request notification permissions
  if (!kIsWeb) {
    // Notification permissions are not needed on the web
    await notificationHandler.requestNotificationPermissions();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EatEase',
      debugShowCheckedModeBanner: false,
      home: kIsWeb
          ? const WelcomeScreen() // Use web-specific screen
          : (Platform.isAndroid
          ? const Splash() // Android-specific screen
          : const WelcomeScreen()), // Default fallback
    );
  }
}
