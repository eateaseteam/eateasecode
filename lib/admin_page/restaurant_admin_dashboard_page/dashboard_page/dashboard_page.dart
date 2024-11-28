import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../android_users/HomePage/RestaurantPage/restaurant_data_manager.dart';

class DashboardPage extends StatelessWidget {
  final RestaurantDataManager _dataManager = RestaurantDataManager();
  final String restaurantId;

  DashboardPage({Key? key, required this.restaurantId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dataManager.getReservationsStream(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No reservations found'));
        }

        List<DocumentSnapshot> reservations = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 24),
              _buildStatusCards(reservations),
              SizedBox(height: 32),
              _buildOrdersByTypeChart(reservations),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCards(List<DocumentSnapshot> reservations) {
    Map<String, int> counts = _getReservationCounts(reservations);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatusCard(
          'Complete\nReservation',
          counts['completed'].toString(),
          Colors.blue[600]!,
          Icons.check_circle_outline,
        ),
        _buildStatusCard(
          'Pending\nReservation',
          counts['pending'].toString(),
          Colors.orange[600]!,
          Icons.pending_outlined,
        ),
        _buildStatusCard(
          'Approved\nReservation',
          counts['approved'].toString(),
          Colors.green[600]!,
          Icons.thumb_up_outlined,
        ),
        _buildStatusCard(
          'Cancelled\nReservation',
          counts['cancelled'].toString(),
          Colors.red[600]!,
          Icons.cancel_outlined,
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersByTypeChart(List<DocumentSnapshot> reservations) {
    Map<String, double> typeData = _getOrdersByType(reservations);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders by Type',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24),
          Container(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: typeData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueAccent,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String type = typeData.keys.elementAt(group.x.toInt());
                      return BarTooltipItem(
                        '$type\n',
                        GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(
                            text: rod.toY.round().toString(),
                            style: GoogleFonts.inter(
                              color: Colors.yellow,
                              fontSize: 16,
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
                        List<String> types = typeData.keys.toList();
                        int index = value.toInt();
                        if (index >= 0 && index < types.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              types[index],
                              style: GoogleFonts.inter(fontSize: 12),
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(fontSize: 12),
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
                  horizontalInterval: 20,
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
                  typeData.length,
                      (index) => _generateBarGroup(index, typeData.values.elementAt(index)),
                ),
              ),
            ),
          ),
        ],
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
            colors: [Colors.orange[300]!, Colors.orange[700]!],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Map<String, int> _getReservationCounts(List<DocumentSnapshot> reservations) {
    Map<String, int> counts = {
      'completed': 0,
      'pending': 0,
      'approved': 0,
      'cancelled': 0,
    };

    for (var reservation in reservations) {
      String status = reservation['status'];
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts;
  }

  Map<String, double> _getOrdersByType(List<DocumentSnapshot> reservations) {
    Map<String, double> typeData = {};

    for (var reservation in reservations) {
      List<dynamic> items = reservation['items'] ?? [];
      for (var item in items) {
        String type = item['type'] ?? 'Uncategorized';
        typeData[type] = (typeData[type] ?? 0) + item['quantity'];
      }
    }

    return typeData;
  }
}

