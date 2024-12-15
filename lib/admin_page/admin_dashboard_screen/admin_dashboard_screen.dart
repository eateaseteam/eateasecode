import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
                  _buildRecentReservations(restaurants),
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

        return Row(
          children: [
            Expanded(child: _buildOverviewCard('Total Customers', data['totalCustomers'].toString(), Icons.book)),
            const SizedBox(width: 16),
            Expanded(child: _buildOverviewCard('Active Restaurants', data['activeRestaurants'].toString(), Icons.restaurant)),
            const SizedBox(width: 16),
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
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReservations(List<DocumentSnapshot> restaurants) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Reservations',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getRecentReservationsStream(restaurants),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<Map<String, dynamic>> recentReservations = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = recentReservations[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[700],
                        child: Text(
                          reservation['restaurantName'][0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(reservation['restaurantName']),
                      subtitle: Text('${reservation['guestCount']} guests'),
                      trailing: Text(
                        DateFormat('MMM d, HH:mm').format(reservation['bookingTimestamp'].toDate()),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<Map<String, dynamic>> _calculateOverviewDataStream(List<DocumentSnapshot> restaurants) async* {
    while (true) {
      int totalCustomersFromReservations = 0;
      int activeRestaurants = 0;
      int totalCustomers = 0;

      try {
        QuerySnapshot customersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
        totalCustomers = customersSnapshot.docs.length;

        for (var restaurant in restaurants) {
          List<Map<String, dynamic>> reservations =
          await _dataManager.getReservationsForRestaurant(restaurant.id);

          totalCustomersFromReservations += reservations.length;

          if (reservations.isNotEmpty) {
            activeRestaurants++;
          }
        }

        yield {
          'totalCustomers': totalCustomers,
          'totalCustomersFromReservations': totalCustomersFromReservations,
          'activeRestaurants': activeRestaurants,
        };
      } catch (e) {
        print('Error calculating overview data: $e');
        yield {
          'totalCustomers': 0,
          'totalCustomersFromReservations': 0,
          'activeRestaurants': 0,
        };
      }

      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Stream<List<Map<String, dynamic>>> _getRecentReservationsStream(List<DocumentSnapshot> restaurants) async* {
    while (true) {
      List<Map<String, dynamic>> allReservations = [];

      for (var restaurant in restaurants) {
        List<Map<String, dynamic>> reservations = await _dataManager.getReservationsForRestaurant(restaurant.id);
        for (var reservation in reservations) {
          allReservations.add({
            ...reservation,
            'restaurantName': restaurant['name'],
          });
        }
      }

      allReservations.sort((a, b) => b['bookingTimestamp'].compareTo(a['bookingTimestamp']));
      yield allReservations.take(5).toList();

      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
