import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../admin_home_screen_page/admin_home_screen_page.dart';
import '../restaurant_admin_dashboard_page/restaurant_admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // Authenticate the user using Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Get the user's UID
      String? userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception("Authentication succeeded, but user ID is null.");
      }

      // Check if the user is an admin
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();

      if (adminDoc.exists) {
        // Log admin login and navigate to Admin Dashboard
        await _logActivity(userId, email, 'Admin');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminHomeScreenPage()),
              (route) => false,
        );
        return;
      }

      // Check if the user is a restaurant admin
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(userId)
          .get();

      if (restaurantDoc.exists) {
        // Log restaurant admin login and navigate to Restaurant Admin Dashboard
        await _logActivity(userId, email, 'Restaurant Admin');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => RestaurantAdminDashboardPage(userId: userId),
          ),
              (route) => false,
        );
        return;
      }

      // If the user doesn't belong to any role
      _showErrorSnackbar('You are not authorized to access this page.');
    } catch (e) {
      _showErrorSnackbar('Login failed: ${e.toString()}');
    }
  }

  Future<void> _logActivity(String userId, String email, String role) async {
    try {
      String collectionName =
      role == 'Admin' ? 'admin_logs' : 'restaurant_logs';
      await FirebaseFirestore.instance.collection(collectionName).add({
        'action': 'Login',
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
        'performedBy': email,
        'userId': userId,
        'formattedTimestamp':
        DateFormat('MMM d \'at\' h:mm a').format(DateTime.now()),
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'lib/assets/app_images/updated_official_logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 12.0),
              Text(
                'Log in to manage operations.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40.0),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                isObscure: false,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16.0),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                isObscure: _isObscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscurePassword = !_isObscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Log In',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required IconData prefixIcon,
    IconButton? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
    );
  }
}
