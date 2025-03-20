import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatease_app_web/admin_page/login_screen/adminResto_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// For date formatting

import '../add_new_admin_screen/add_new_admin_screen.dart';
import '../admin_dashboard_screen/admin_dashboard_screen.dart';
import '../customer_list_data/customer_list_data.dart';
import '../list_or_add_restaurant_data/list_or_add_restaurant_data.dart';
import '../recent_activity_screen/recent_activity_screen.dart';

class AdminHomeScreenPage extends StatefulWidget {
  const AdminHomeScreenPage({super.key});

  @override
  _AdminHomeScreenPageState createState() => _AdminHomeScreenPageState();
}

class _AdminHomeScreenPageState extends State<AdminHomeScreenPage> {
  String _currentPage = 'Dashboard';
  bool isDrawerOpen = true;
  String? _adminEmail = 'Guest Admin'; // Default to "Guest Admin"

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
    _fetchAdminEmail();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchAdminEmail();
      } else {
        setState(() {
          _adminEmail = 'Guest Admin';
        });
      }
    });
  }

  Future<void> _fetchAdminEmail() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(currentUser.uid)
            .get();

        if (adminDoc.exists) {
          setState(() {
            _adminEmail = adminDoc['email'];
          });
        }
      }
    } catch (e) {
      print('Error fetching admin email: $e');
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout', style: GoogleFonts.poppins()),
          content: Text('Are you sure you want to log out?',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel logout
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
            ),
          ],
        );
      },
    );

    // Proceed with logout if confirmed
    if (shouldLogout == true) {
      try {
        await _logAdminLogout(); // Log the admin logout
        await FirebaseAuth.instance.signOut(); // Sign out from Firebase Auth
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const AdminLoginPage()), // Navigate to LoginAsScreen
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logAdminLogout() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('admin_logs').add({
          'action': 'Logout',
          'details': 'Admin logged out',
          'timestamp': FieldValue.serverTimestamp(),
          'performedBy': _adminEmail ?? 'Unknown',
          'adminId': currentUser.uid,
        });
      } catch (e) {
        print('Error logging admin logout: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue[600]),
        title:
            const Text('EatEase Admin', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(isDrawerOpen ? Icons.menu_open : Icons.menu),
          onPressed: () {
            setState(() {
              isDrawerOpen = !isDrawerOpen;
            });
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Divider(
                  color: Colors.grey[400],
                  height: 24,
                  thickness: 1,
                ),
                const SizedBox(width: 8.0),
                Text(
                  _adminEmail ?? 'Guest Admin',
                  // Display the email or Guest Admin
                  style: GoogleFonts.inter(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDrawerOpen)
            Container(
              width: 250,
              color: Colors.white,
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Row(
                      children: [
                        Image.asset(
                            'lib/assets/app_images/updated_official_logo.png',
                            width: 150),
                      ],
                    ),
                  ),
                  _buildListTile(
                      'Dashboard', Icons.dashboard, Colors.blue[600]!),
                  _buildListTile('Admin', Icons.person, Colors.blue[600]!),
                  _buildListTile(
                      'Restaurant', Icons.restaurant, Colors.blue[600]!),
                  _buildListTile(
                      'Recent Activity', Icons.history, Colors.blue[600]!),
                  // Log Out Tile with red icon
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text(
                      'Log Out',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: _logout, // Log out when tapped
                  ),
                ],
              ),
            ),
          Expanded(
            child: _currentPage == 'Dashboard'
                ? AdminDashboardScreen()
                : _currentPage == 'Admin'
                    ? const AdminPanel()
                    : _currentPage == 'Customer'
                        ? const CustomerListPage()
                        : _currentPage == 'Restaurant'
                            ? const RestaurantManagement()
                            : _currentPage == 'Recent Activity'
                                ? const RecentActivityScreen()
                                : Center(
                                    child: Text('Content for $_currentPage')),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData? icon, Color color) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        setState(() => _currentPage = title);
      },
      selectedColor: Colors.blue[600],
      selectedTileColor: Colors.blue[100],
      selected: _currentPage == title,
    );
  }
}
