import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../SignIn_Page/sign_in_screen.dart';
import 'package:http/http.dart' as http;

import '../HomePage/home_screen_container.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _checkInternetConnectionAndProceed();
  }

  // Check for internet connection and proceed based on its availability
  Future<void> _checkInternetConnectionAndProceed() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    // Check connectivity type
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      print('Connected via Mobile Data');
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      print('Connected via WiFi');
    } else {
      print('No internet connection');
      _showNoInternetDialog();
      return; // Exit the function if no connection
    }

    // Check if the internet is actually working
    bool isInternetAvailable = await _checkInternetAvailability();
    if (isInternetAvailable) {
      // Internet is available, proceed with user session check
      _checkUserSession();
    } else {
      // Internet connection is present but no access, show a message
      _showNoInternetDialog();
    }
  }

  Future<bool> _checkInternetAvailability() async {
    try {
      print('Attempting to check internet availability...');
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('Internet is available.');
        return true;
      } else {
        print(
            'No internet access detected, status code: ${response.statusCode}');
        return false;
      }
    } on TimeoutException catch (_) {
      print('TimeoutException: No internet access or request timed out.');
      return false;
    } catch (e) {
      print('Exception: $e');
      return false;
    }
  }

  // Check if the user is logged in and handle navigation
  Future<void> _checkUserSession() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, navigate to the home screen
      _navigateToHomeScreen(user.email!);
    } else {
      // Navigate to the sign-in screen
      _navigateToSignInScreen();
    }
  }

  // Navigate to the sign-in screen
  void _navigateToSignInScreen() {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    });
  }

  // Navigate to the home screen with user data
  void _navigateToHomeScreen(String email) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => HomeScreenContainer(
                email: email)), // Pass the email to HomeScreenContainer
      );
    });
  }

  // Show no internet connection dialog
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Internet Connection',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please connect to the internet and try again.',
                  style: GoogleFonts.poppins(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Optionally, you can add logic to retry connection or navigate
                        // For example, you might want to open settings or retry logic here
                        exit(0); // Close the app if desired
                      },
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Optionally, you can add logic to retry connection or navigate
                        // For example, you might want to open settings or retry logic here
                        exit(0); // Close the app if desired
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close App',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Image.asset(
              'lib/assets/app_images/updated_official_logo.png',
              fit: BoxFit.contain, // Adjust as needed for your layout
            ),
          ),
        ),
      ),
    );
  }
}
