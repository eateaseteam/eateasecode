import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../add_new_admin_screen/add_new_admin_screen.dart';
import '../admin_dashboard_screen/admin_dashboard_screen.dart';
import '../customer_list_data/customer_list_data.dart';
import '../list_or_add_restaurant_data/list_or_add_restaurant_data.dart';
import '../welcome_screen/log_in_as_screen.dart';

class AdminHomeScreenPage extends StatefulWidget {
  final String? userId; // Make userId optional

  AdminHomeScreenPage({this.userId});

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
    if (widget.userId != null) {
      _fetchAdminEmail(); // Fetch admin email only if userId is provided
    }
  }

  Future<void> _fetchAdminEmail() async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.userId)
          .get();

      if (adminDoc.exists) {
        setState(() {
          _adminEmail = adminDoc['email']; // Fetch the email from Firestore
        });
      }
    } catch (e) {
      print('Error fetching admin email: $e');
    }
  }

  // Log out the user and navigate to the Login screen
  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout', style: GoogleFonts.poppins()),
          content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel logout
              },
            ),
            TextButton(
              child: Text('Logout', style: TextStyle(color: Colors.red)),
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
        await FirebaseAuth.instance.signOut(); // Sign out from Firebase Auth
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginAsScreen()), // Navigate to LoginAsScreen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue[600]),
        title: Text('EatEase Admin', style: TextStyle(color: Colors.black)),
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
            padding: EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Divider(
                  color: Colors.grey[400],
                  height: 24,
                  thickness: 1,
                ),
                SizedBox(width: 8.0),
                Text(
                  _adminEmail ?? 'Guest Admin', // Display the email or Guest Admin
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
                    decoration: BoxDecoration(color: Colors.white),
                    child: Row(
                      children: [
                        Image.asset('lib/assets/app_images/official_logo.png', width: 150),
                      ],
                    ),
                  ),
                  _buildListTile('Dashboard', Icons.dashboard, Colors.blue[600]!),
                  _buildListTile('Admin', Icons.person, Colors.blue[600]!),
                  _buildListTile('Customer', Icons.person_outline, Colors.blue[600]!),
                  _buildListTile('Restaurant', Icons.restaurant, Colors.blue[600]!),
                  // Log Out Tile with red icon
                  ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
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
                ? AdminPanel()
                : _currentPage == 'Customer'
                ? CustomerListPage()
                : _currentPage == 'Restaurant'
                ? RestaurantManagement()
                : Center(child: Text('Content for $_currentPage')),
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
