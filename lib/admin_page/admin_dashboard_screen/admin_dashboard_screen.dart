import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../android_users/HomePage/RestaurantPage/restaurant_data_manager.dart';

class AdminDashboardScreen extends StatelessWidget {
  final RestaurantDataManager _dataManager = RestaurantDataManager();

  AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dataManager.getRestaurantsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No restaurants found'));
        }

        List<DocumentSnapshot> restaurants = snapshot.data!.docs;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildOverviewCards(restaurants),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(List<DocumentSnapshot> restaurants) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _calculateOverviewDataStream(restaurants),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        final data = snapshot.data!;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Total Customers',
                    data['totalCustomers'].toString(),
                    Icons.account_circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    'Active Restaurants',
                    data['activeRestaurants'].toString(),
                    Icons.restaurant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    'Total Admins',
                    data['totalAdmins'].toString(),
                    Icons.admin_panel_settings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Overview Graph',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildGraph(data),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue[700], size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph(Map<String, dynamic> data) {
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            _buildBarChartGroupData(
                0, data['totalCustomers'].toDouble(), Colors.blue),
            _buildBarChartGroupData(
                1, data['activeRestaurants'].toDouble(), Colors.green),
            _buildBarChartGroupData(
                2, data['totalAdmins'].toDouble(), Colors.orange),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('Customers');
                    case 1:
                      return Text('Restaurants');
                    case 2:
                      return Text('Admins');
                    default:
                      return Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: true),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarChartGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Stream<Map<String, dynamic>> _calculateOverviewDataStream(
      List<DocumentSnapshot> restaurants) async* {
    while (true) {
      int totalCustomers = 0;
      int activeRestaurants = 0;
      int totalAdmins = 0;

      try {
        // Fetch total customers
        QuerySnapshot customersSnapshot =
            await FirebaseFirestore.instance.collection('users').get();
        totalCustomers = customersSnapshot.docs.length;

        // Fetch total admins
        QuerySnapshot adminsSnapshot =
            await FirebaseFirestore.instance.collection('admins').get();
        totalAdmins = adminsSnapshot.docs.length;

        // Count active restaurants based on reservations
        for (var restaurant in restaurants) {
          List<Map<String, dynamic>> reservations =
              await _dataManager.getReservationsForRestaurant(restaurant.id);

          if (reservations.isNotEmpty) {
            activeRestaurants++;
          }
        }

        yield {
          'totalCustomers': totalCustomers,
          'activeRestaurants': activeRestaurants,
          'totalAdmins': totalAdmins,
        };
      } catch (e) {
        print('Error calculating overview data: $e');
        yield {
          'totalCustomers': 0,
          'activeRestaurants': 0,
          'totalAdmins': 0,
        };
      }

      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
