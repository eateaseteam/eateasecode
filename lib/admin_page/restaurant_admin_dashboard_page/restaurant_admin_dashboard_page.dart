import 'package:eatease_app_web/admin_page/restaurant_admin_dashboard_page/reservation_history_page/reservation_history_page.dart';
import 'package:eatease_app_web/admin_page/restaurant_admin_dashboard_page/reservation_page/reservation_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_page/dashboard_page.dart';
import 'menu_page/menu_page.dart';
import 'orders_page/orders_page.dart';

class RestaurantAdminDashboardPage extends StatefulWidget {
  @override
  _RestaurantAdminDashboardPageState createState() => _RestaurantAdminDashboardPageState();
}

class _RestaurantAdminDashboardPageState extends State<RestaurantAdminDashboardPage> {
  String _currentPage = 'Dashboard';
  bool isDrawerOpen = true;

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
                  _buildListTile('Dashboard', Icons.dashboard, color: Colors.orange),
                  _buildListTile('Menu', Icons.menu, color: Colors.orange),
                  _buildListTile('Reservation', Icons.calendar_today, color: Colors.orange),
                  _buildListTile('Orders', Icons.shopping_cart, color: Colors.orange),
                  _buildListTile('History', Icons.history, color: Colors.orange),
                ],
              ),
            ),
          Expanded(
            child: _currentPage == 'Dashboard'
                ? DashboardPage()
                : _currentPage == 'Menu'
                ? MenuPage()  // This will display the MenuPage
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

  Widget _buildListTile(String title, IconData? icon, {Color color = Colors.orange}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Text(title),
      onTap: () {
        setState(() => _currentPage = title);
      },
      splashColor: Colors.grey.withOpacity(0.3),
      hoverColor: Colors.grey.withOpacity(0.1),
    );
  }
}