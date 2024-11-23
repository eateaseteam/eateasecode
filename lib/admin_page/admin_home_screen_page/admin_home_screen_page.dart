import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../add_new_admin_screen/add_new_admin_screen.dart';
import '../admin_dashboard_screen/admin_dashboard_screen.dart';
import '../customer_list_data/customer_list_data.dart';
import '../list_or_add_restaurant_data/list_or_add_restaurant_data.dart';

class AdminHomeScreenPage extends StatefulWidget {
  @override
  _AdminHomeScreenPageState createState() => _AdminHomeScreenPageState();
}

class _AdminHomeScreenPageState extends State<AdminHomeScreenPage> {
  String _currentPage = 'Dashboard';
  bool isDrawerOpen = true;

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
                  'admin@gmail.com',
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
                ? ListOrAddRestaurantData()
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