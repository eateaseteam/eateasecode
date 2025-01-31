import 'package:eatease_app_web/admin_page/login_screen/adminResto_login_screen.dart';
import 'package:eatease_app_web/admin_page/restaurant_admin_dashboard_page/recent_activity_page/recent_activity_page.dart';
import 'package:eatease_app_web/admin_page/restaurant_admin_dashboard_page/reservation_history_page/reservation_history_page.dart';
import 'package:eatease_app_web/admin_page/restaurant_admin_dashboard_page/reservation_page/reservation_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dashboard_page/dashboard_page.dart';
import 'menu_page/menu_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantAdminDashboardPage extends StatefulWidget {
  final String userId;

  const RestaurantAdminDashboardPage({super.key, required this.userId});

  @override
  _RestaurantAdminDashboardPageState createState() =>
      _RestaurantAdminDashboardPageState();
}

class _RestaurantAdminDashboardPageState
    extends State<RestaurantAdminDashboardPage> {
  String _currentPage = 'Dashboard';
  bool isDrawerOpen = true;
  String _restaurantName = '';
  String _restaurantLogoUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantDetails();
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.userId)
          .get();

      if (restaurantDoc.exists) {
        setState(() {
          _restaurantName = restaurantDoc['name'] ?? 'Restaurant Name';
          _restaurantLogoUrl = restaurantDoc['logoUrl'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _restaurantName = 'Restaurant not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _restaurantName = 'Error fetching data';
      });
    }
  }

  Future<void> _logOut() async {
    final shouldLogOut = await showDialog<bool>(
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
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldLogOut == true) {
      try {
        // Get the current user's email
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email ?? 'Unknown User';

        // Log the logout activity in Firestore under the specific restaurant
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.userId)
            .collection('logout_logs') // Use a sub-collection for logout logs
            .add({
          'userId': widget.userId,
          'email': email, // Record the email of the user who logged out
          'action': 'Logout',
          'timestamp': FieldValue.serverTimestamp(),
          'formattedTimestamp':
              DateFormat('MMM d \'at\' h:mm a').format(DateTime.now()),
        });

        // Sign out from Firebase Auth
        await FirebaseAuth.instance.signOut();

        // Navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginPage()),
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
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text('EATEASE', style: TextStyle(color: Colors.black)),
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
                _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _restaurantName.isNotEmpty
                            ? _restaurantName
                            : 'Loading...',
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
                        _isLoading
                            ? const CircularProgressIndicator()
                            : _restaurantLogoUrl.isNotEmpty
                                ? Image.network(_restaurantLogoUrl, width: 150)
                                : Image.asset(
                                    'lib/assets/app_images/updated_official_logo.png',
                                    width: 150,
                                  ),
                      ],
                    ),
                  ),
                  _buildListTile('Dashboard', Icons.dashboard,
                      color: Colors.orange),
                  _buildListTile('Menu', Icons.menu, color: Colors.orange),
                  _buildListTile('Reservation', Icons.calendar_today,
                      color: Colors.orange),
                  _buildListTile('Reservation History', Icons.history,
                      color: Colors.orange),
                  _buildListTile('Recent Activity', Icons.timeline,
                      color: Colors.orange),
                  _buildListTile('Logout', Icons.logout,
                      color: Colors.red, onTap: _logOut),
                ],
              ),
            ),
          Expanded(
            child: _currentPage == 'Dashboard'
                ? DashboardPage(restaurantId: widget.userId)
                : _currentPage == 'Menu'
                    ? MenuPage(userId: widget.userId)
                    : _currentPage == 'Reservation'
                        ? ReservationPage(restaurantId: widget.userId)
                        : _currentPage == 'Reservation History'
                            ? ReservationHistoryPage(
                                restaurantId: widget.userId)
                            : _currentPage == 'Recent Activity'
                                ? RecentActivityPage(
                                    restaurantId: widget.userId)
                                : Center(
                                    child: Text('Content for $_currentPage')),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData? icon,
      {Color color = Colors.orange, Function()? onTap}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Text(title),
      onTap: onTap ??
          () {
            setState(() => _currentPage = title);
          },
      splashColor: Colors.grey.withOpacity(0.3),
      hoverColor: Colors.grey.withOpacity(0.1),
    );
  }
}
