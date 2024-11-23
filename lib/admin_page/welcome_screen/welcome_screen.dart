import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../login_screen/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), _navigateToNextScreen);
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
          decoration: BoxDecoration(
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
                  SizedBox(height: 40),
                  _buildWelcomeText(),
                  SizedBox(height: 20),
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
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'lib/assets/app_images/official_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    ).animate()
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
    ).animate()
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        "Streamline your restaurant operations with our all-in-one booking and services management solution.",
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
    ).animate()
        .fadeIn(duration: 800.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print("User is already logged in: ${user.uid}");
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('ADMIN_ACCOUNTS')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          if (!data.containsKey('full_name') || !data.containsKey('role')) {
            _showErrorSnackBar("User data is incomplete.");
            print("Incomplete user data for user: ${user.uid}");
            return;
          }

          String fullName = data['full_name'];
          String role = data['role'];

          print("User data: Full Name: $fullName, Role: $role");

          if (role == 'admin') {
            _showWelcomeSnackBar(fullName);
            // Uncomment the line below when AdminRestaurantLoginScreen is implemented
            // _navigateTo(AdminRestaurantLoginScreen(userId: user.uid));
          } else {
            _showErrorSnackBar("Unexpected role: $role");
            print("Unexpected role for user: ${user.uid}, Role: $role");
            return;
          }
        } else {
          await FirebaseAuth.instance.signOut();
          _showErrorSnackBar("User document does not exist. Logging out.");
          print("User document does not exist for user: ${user.uid}. Logging out.");
          _navigateTo(AdminRestaurantLoginScreen());
        }
      } catch (e) {
        _showErrorSnackBar("Error fetching user data: $e");
        print("Error fetching user data for user: ${user.uid}, Error: $e");
      }
    } else {
      print("User is not logged in. Navigating to admin login page.");
      _navigateTo(AdminRestaurantLoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showWelcomeSnackBar(String fullName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Welcome, $fullName!",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
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
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

