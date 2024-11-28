import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../android_users/HomePage/RestaurantPage/restaurant_data_manager.dart';

class ReservationHistoryPage extends StatefulWidget {
  final String restaurantId;

  const ReservationHistoryPage({Key? key, required this.restaurantId}) : super(key: key);

  @override
  _ReservationHistoryPageState createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final RestaurantDataManager _dataManager = RestaurantDataManager();

  final Color _primaryColor = Color(0xFF4A90E2);
  final Color _secondaryColor = Color(0xFF5C6BC0);
  final Color _backgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 16),
              Expanded(child: _buildReservationList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reservation History',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          width: 250,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search history...',
              prefixIcon: Icon(Icons.search, color: _primaryColor),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _dataManager.getReservationsStream(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No reservations found.', style: TextStyle(color: Colors.grey[600])));
        }

        List<DocumentSnapshot> allReservations = snapshot.data!.docs;
        List<DocumentSnapshot> filteredReservations = _filterReservations(allReservations);

        return ListView(
          children: [
            _buildHistorySection('This Month', _getReservationsForPeriod(filteredReservations, 0, 30)),
            SizedBox(height: 16),
            _buildHistorySection('Last Month', _getReservationsForPeriod(filteredReservations, 30, 60)),
            SizedBox(height: 16),
            _buildHistorySection('Older', _getReservationsForPeriod(filteredReservations, 60, null)),
          ],
        );
      },
    );
  }

  List<DocumentSnapshot> _filterReservations(List<DocumentSnapshot> reservations) {
    String searchTerm = _searchController.text.toLowerCase();
    return reservations.where((reservation) {
      Map<String, dynamic> data = reservation.data() as Map<String, dynamic>;
      return data['userEmail'].toString().toLowerCase().contains(searchTerm) ||
          data['referenceNumber'].toString().toLowerCase().contains(searchTerm);
    }).toList();
  }

  List<DocumentSnapshot> _getReservationsForPeriod(List<DocumentSnapshot> reservations, int startDays, int? endDays) {
    DateTime now = DateTime.now();
    return reservations.where((reservation) {
      DateTime reservationDate = (reservation['reservationDateTime'] as Timestamp).toDate();
      int daysDifference = now.difference(reservationDate).inDays;
      return daysDifference >= startDays && (endDays == null || daysDifference < endDays);
    }).toList();
  }

  Widget _buildHistorySection(String title, List<DocumentSnapshot> reservations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _secondaryColor,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              columns: [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Guests')),
                DataColumn(label: Text('Date/Time')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: reservations.map((reservation) {
                Map<String, dynamic> data = reservation.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(reservation.id)),
                    DataCell(Text(data['userEmail'] ?? 'N/A')),
                    DataCell(Text(data['guestCount'].toString())),
                    DataCell(Text(DateFormat('MM/dd/yy HH:mm').format((data['reservationDateTime'] as Timestamp).toDate()))),
                    DataCell(_buildStatusBadge(data['status'])),
                    DataCell(_buildActionButtons(reservation.id)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = _primaryColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(String reservationId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.visibility, color: _primaryColor),
          onPressed: () => _showReservationDetails(reservationId),
          tooltip: 'View Details',
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteReservation(reservationId),
          tooltip: 'Delete',
        ),
      ],
    );
  }

  void _showReservationDetails(String reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reservation Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: FutureBuilder<DocumentSnapshot>(
          future: _dataManager.getReservationDetails(widget.restaurantId, reservationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _primaryColor));
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Reservation not found', style: TextStyle(color: Colors.grey[600]));
            }

            Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailItem('Customer', data['userEmail']),
                _detailItem('Guests', data['guestCount'].toString()),
                _detailItem('Date', DateFormat('MM/dd/yy HH:mm').format((data['reservationDateTime'] as Timestamp).toDate())),
                _detailItem('Status', data['status']),
                _detailItem('Total Price', 'PHP ${data['totalPrice']}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  void _confirmDeleteReservation(String reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Deletion', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this reservation?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReservation(reservationId);
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _deleteReservation(String reservationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('reservations')
          .doc(reservationId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting reservation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}