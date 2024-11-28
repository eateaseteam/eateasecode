import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../android_users/HomePage/RestaurantPage/restaurant_data_manager.dart';

class AdminDashboardScreen extends StatelessWidget {
  final RestaurantDataManager _dataManager = RestaurantDataManager();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dataManager.getRestaurantsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No restaurants found'));
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
                  SizedBox(height: 24),
                  _buildOverviewCards(restaurants),
                  SizedBox(height: 24),
                  _buildReservationsChart(restaurants),
                  SizedBox(height: 24),
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
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No data available'));
        }

        final data = snapshot.data!;

        return Row(
          children: [
            Expanded(child: _buildOverviewCard('Total Reservations', data['totalReservations'].toString(), Icons.book)),
            SizedBox(width: 16),
            Expanded(child: _buildOverviewCard('Active Restaurants', data['activeRestaurants'].toString(), Icons.restaurant)),
            SizedBox(width: 16),
            Expanded(child: _buildOverviewCard('Avg. Reservations', data['avgReservations'].toStringAsFixed(1), Icons.analytics)),
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
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsChart(List<DocumentSnapshot> restaurants) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservations per Restaurant',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            Container(
              height: 300,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getReservationsStream(restaurants),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  List<Map<String, dynamic>> restaurantData = snapshot.data!;
                  restaurantData.sort((a, b) => b['reservations'].compareTo(a['reservations']));

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: restaurantData.first['reservations'].toDouble() * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.blueAccent,
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${restaurantData[group.x.toInt()]['name']}\n',
                              GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${rod.toY.round()} reservations',
                                  style: GoogleFonts.poppins(
                                    color: Colors.yellow,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) return Text('');
                              int index = value.toInt();
                              if (index >= 0 && index < restaurantData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    restaurantData[index]['name'],
                                    style: GoogleFonts.poppins(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        restaurantData.length,
                            (index) => _generateBarGroup(index, restaurantData[index]['reservations'].toDouble()),
                      ),
                    ),
                  );
                },
              ),
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
            SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getRecentReservationsStream(restaurants),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<Map<String, dynamic>> recentReservations = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: recentReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = recentReservations[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[700],
                        child: Text(
                          reservation['restaurantName'][0],
                          style: TextStyle(color: Colors.white),
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

  BarChartGroupData _generateBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[700]!],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Stream<Map<String, dynamic>> _calculateOverviewDataStream(List<DocumentSnapshot> restaurants) async* {
    while (true) {
      int totalReservations = 0;
      int activeRestaurants = 0;

      for (var restaurant in restaurants) {
        List<Map<String, dynamic>> reservations = await _dataManager.getReservationsForRestaurant(restaurant.id);
        totalReservations += reservations.length;
        if (reservations.isNotEmpty) {
          activeRestaurants++;
        }
      }

      double avgReservations = activeRestaurants > 0 ? totalReservations / activeRestaurants : 0;

      yield {
        'totalReservations': totalReservations,
        'activeRestaurants': activeRestaurants,
        'avgReservations': avgReservations,
      };

      await Future.delayed(Duration(seconds: 10)); // Adjust the delay as needed
    }
  }

  Stream<List<Map<String, dynamic>>> _getReservationsStream(List<DocumentSnapshot> restaurants) async* {
    while (true) {
      List<Map<String, dynamic>> allReservations = [];

      for (var restaurant in restaurants) {
        List<Map<String, dynamic>> reservations = await _dataManager.getReservationsForRestaurant(restaurant.id);
        allReservations.add({
          'name': restaurant['name'],
          'reservations': reservations.length,
        });
      }

      yield allReservations;
      await Future.delayed(Duration(seconds: 10)); // Adjust the delay as needed
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

      await Future.delayed(Duration(seconds: 10)); // Adjust the delay as needed
    }
  }
}