import 'package:eatease_app_web/admin_page/restaurant_admin_dashboard_page/reservation_history_page/reservation_history_page.dart';
import 'package:eatease_app_web/admin_page/restaurant_admin_dashboard_page/reservation_page/reservation_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../welcome_screen/log_in_as_screen.dart';
import 'dashboard_page/dashboard_page.dart';
import 'menu_page/menu_page.dart';
import 'orders_page/orders_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantAdminDashboardPage extends StatefulWidget {
  final String userId; // Accept the userId passed from the login screen

  RestaurantAdminDashboardPage({required this.userId});

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
      // Fetch restaurant data using UID as the document ID
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.userId) // Use the userId to fetch the restaurant document
          .get();

      if (restaurantDoc.exists) {
        // Successfully found the restaurant
        setState(() {
          _restaurantName = restaurantDoc['name'] ?? 'Restaurant Name'; // Fetch restaurant name
          _restaurantLogoUrl = restaurantDoc['logoUrl'] ?? ''; // Fetch logoUrl if available
          _isLoading = false; // Update loading state to false
        });
      } else {
        // Handle case where no restaurant is found with this UID
        setState(() {
          _isLoading = false;
          _restaurantName = 'Restaurant not found'; // Provide feedback if not found
        });
      }
    } catch (e) {
      // Handle any errors during data fetching
      setState(() {
        _isLoading = false;
        _restaurantName = 'Error fetching data'; // Provide error feedback
      });
    }
  }

  // Function to log out the user
  Future<void> _logOut() async {
    await FirebaseAuth.instance.signOut(); // Sign the user out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginAsScreen()), // Navigate to the login screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.orange),
        title: Text('EATEASE', style: TextStyle(color: Colors.black)),
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
                _isLoading
                    ? CircularProgressIndicator()
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
                    decoration: BoxDecoration(color: Colors.white),
                    child: Row(
                      children: [
                        _isLoading
                            ? CircularProgressIndicator()
                            : _restaurantLogoUrl.isNotEmpty
                            ? Image.network(_restaurantLogoUrl, width: 150)
                            : Image.asset('lib/assets/app_images/official_logo.png', width: 150),
                      ],
                    ),
                  ),
                  _buildListTile('Dashboard', Icons.dashboard, color: Colors.orange),
                  _buildListTile('Menu', Icons.menu, color: Colors.orange),
                  _buildListTile('Reservation', Icons.calendar_today, color: Colors.orange),
                  _buildListTile('Orders', Icons.shopping_cart, color: Colors.orange),
                  _buildListTile('History', Icons.history, color: Colors.orange),
                  // Add Logout tile
                  _buildListTile('Logout', Icons.logout, color: Colors.red, onTap: _logOut),
                ],
              ),
            ),
          Expanded(
            child: _currentPage == 'Dashboard'
                ? DashboardPage()
                : _currentPage == 'Menu'
                ? MenuPage(userId: widget.userId) // This will display the MenuPage
                : _currentPage == 'Reservation'
                ? ReservationPage()
                : _currentPage == 'Orders'
                ? OrdersPage()
                : _currentPage == 'History'
                ? ReservationHistoryPage()
                : Center(child: Text('Content for $_currentPage')),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData? icon, {Color color = Colors.orange, Function()? onTap}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Text(title),
      onTap: onTap ?? () {
        setState(() => _currentPage = title);
      },
      splashColor: Colors.grey.withOpacity(0.3),
      hoverColor: Colors.grey.withOpacity(0.1),
    );
  }
}
