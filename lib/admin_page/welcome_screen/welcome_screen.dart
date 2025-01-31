import 'package:eatease_app_web/admin_page/login_screen/adminResto_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// Import admin screen
import '../admin_home_screen_page/admin_home_screen_page.dart';
import '../restaurant_admin_dashboard_page/restaurant_admin_dashboard_page.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _navigateToNextScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _navigateToNextScreen,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5F7FA), Color(0xFFE4E7EB)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildWelcomeText(),
                  const SizedBox(height: 20),
                  _buildDescription(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'lib/assets/app_images/updated_official_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    )
        .animate()
        .scale(duration: 800.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 600.ms);
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          "Welcome to",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        Text(
          "Eatease",
          style: GoogleFonts.poppins(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            letterSpacing: 1.2,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        "Streamline your restaurant operations with our all-in-one booking and services management solution.",
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print("User is already logged in: ${user.uid}");
      try {
        if (user.email == null) {
          _showErrorSnackBar("Email is null. Unable to proceed.");
          return; // Handle the case where email is null
        }

        // Fetch the restaurant document using UID as the document ID
        DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(user.uid) // Use UID to fetch the restaurant document
            .get();

        // Fetch the admin document using UID
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid) // Use UID for admin
            .get();

        // If a restaurant is found
        if (restaurantDoc.exists) {
          var restaurantData = restaurantDoc.data() as Map<String, dynamic>;
          String restaurantName = restaurantData['name'] ??
              'Restaurant Name'; // Safely fetch restaurant name
          _showWelcomeSnackBar(restaurantName);
          _navigateTo(RestaurantAdminDashboardPage(
              userId: user.uid)); // Pass UID to Restaurant screen
        }
        // If an admin is found
        else if (adminDoc.exists) {
          var adminData = adminDoc.data() as Map<String, dynamic>;
          String fullName =
              adminData['full_name'] ?? 'Admin Name'; // Safely fetch admin name
          _showWelcomeSnackBar(fullName);
          _navigateTo(const AdminHomeScreenPage()); // Remove userId parameter
        } else {
          await FirebaseAuth.instance.signOut();
          _showErrorSnackBar("No matching data found. Logging out.");
          print("No matching data for user: ${user.uid}. Logging out.");
          _navigateTo(const AdminLoginPage());
        }
      } catch (e) {
        _showErrorSnackBar("Error fetching user data: $e");
        print("Error fetching user data for user: ${user.uid}, Error: $e");
      }
    } else {
      print("User is not logged in. Navigating to login page.");
      _navigateTo(const AdminLoginPage());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showWelcomeSnackBar(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Welcome, $name!",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
