import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../android_users/HomePage/RestaurantPage/restaurant_data_manager.dart';

class ReservationHistoryPage extends StatefulWidget {
  final String restaurantId;

  const ReservationHistoryPage({super.key, required this.restaurantId});

  @override
  _ReservationHistoryPageState createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final RestaurantDataManager _dataManager = RestaurantDataManager();

  //final CollectionReference _logsCollection = FirebaseFirestore.instance.collection('reservation_history_logs');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Color _primaryColor = const Color(0xFF4A90E2);
  final Color _secondaryColor = const Color(0xFF5C6BC0);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  Stream<QuerySnapshot> _getRecentReservationHistoryStream() {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('recent_reservation_history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _logActivity(String action, Map<String, dynamic> details) async {
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('reservation_history_page_logs')
          .add({
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'performedBy': _auth.currentUser?.email ?? 'Unknown',
        'restaurantId': widget.restaurantId,
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

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
              const SizedBox(height: 16),
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
        SizedBox(
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
      stream: _getRecentReservationHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('No reservations found.',
                  style: TextStyle(color: Colors.grey[600])));
        }

        List<DocumentSnapshot> allReservations = snapshot.data!.docs;
        List<DocumentSnapshot> filteredReservations =
            _filterReservations(allReservations);

        return ListView(
          children: [
            _buildHistorySection('This Month',
                _getReservationsForPeriod(filteredReservations, 0, 30)),
            const SizedBox(height: 16),
            _buildHistorySection('Last Month',
                _getReservationsForPeriod(filteredReservations, 30, 60)),
            const SizedBox(height: 16),
            _buildHistorySection('Older',
                _getReservationsForPeriod(filteredReservations, 60, null)),
          ],
        );
      },
    );
  }

  List<DocumentSnapshot> _filterReservations(
      List<DocumentSnapshot> reservations) {
    String searchTerm = _searchController.text.toLowerCase();
    return reservations.where((reservation) {
      Map<String, dynamic> data = reservation.data() as Map<String, dynamic>;
      Map<String, dynamic> reservationData =
          data['reservationData'] as Map<String, dynamic>;
      return reservationData['userEmail']
              .toString()
              .toLowerCase()
              .contains(searchTerm) ||
          reservationData['referenceNumber']
              .toString()
              .toLowerCase()
              .contains(searchTerm) ||
          reservationData['status']
              .toString()
              .toLowerCase()
              .contains(searchTerm);
    }).toList();
  }

  List<DocumentSnapshot> _getReservationsForPeriod(
      List<DocumentSnapshot> reservations, int startDays, int? endDays) {
    DateTime now = DateTime.now();
    return reservations.where((reservation) {
      DateTime reservationDate =
          (reservation['reservationData']['reservationDateTime'] as Timestamp)
              .toDate();
      int daysDifference = now.difference(reservationDate).inDays;
      return daysDifference >= startDays &&
          (endDays == null || daysDifference < endDays);
    }).toList();
  }

  Widget _buildHistorySection(
      String title, List<DocumentSnapshot> reservations) {
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
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Guests')),
                DataColumn(label: Text('Date/Time')),
                DataColumn(label: Text('Status')),
              ],
              rows: reservations.map((reservation) {
                Map<String, dynamic> data =
                    reservation.data() as Map<String, dynamic>;
                Map<String, dynamic> reservationData =
                    data['reservationData'] as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(reservation.id)), // Updated line
                    DataCell(Text(reservationData['userEmail'] ?? 'N/A')),
                    DataCell(Text(reservationData['guestCount'].toString())),
                    DataCell(Text(DateFormat('MM/dd/yy h:mm a').format(
                        (reservationData['reservationDateTime'] as Timestamp)
                            .toDate()))),
                    DataCell(_buildStatusBadge(reservationData['status'])),
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
    switch (status.toLowerCase()) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          icon: const Icon(Icons.delete, color: Colors.red),
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
        title: Text('Reservation Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: FutureBuilder<DocumentSnapshot>(
          future: _dataManager.getReservationDetails(
              widget.restaurantId, reservationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: _primaryColor));
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Reservation not found',
                  style: TextStyle(color: Colors.grey[600]));
            }

            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailItem('Customer', data['userEmail']),
                  _detailItem('Guests', data['guestCount'].toString()),
                  _detailItem(
                      'Date',
                      DateFormat('MM/dd/yy h:mm a').format(
                          (data['reservationDateTime'] as Timestamp).toDate())),
                  _detailItem('Status', data['status']),
                  _detailItem('Total Price', 'PHP ${data['totalPrice']}'),
                  const SizedBox(height: 16),
                  Text('Order Items',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  ...(data['items'] as List<dynamic>).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name'], style: GoogleFonts.poppins()),
                            Text('x${item['quantity']}',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Text('Order Notes',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(data['orderNotes'] ?? 'No order notes',
                      style: GoogleFonts.poppins()),
                  if (data['status'] == 'cancelled') ...[
                    const SizedBox(height: 16),
                    Text('Cancellation Reason',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(data['cancellationReason'] ?? 'No reason provided',
                        style: GoogleFonts.poppins()),
                  ],
                ],
              ),
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
        title: Text('Confirm Deletion',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this reservation?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReservation(reservationId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white, // Sets the text color to white
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteReservation(String reservationId) async {
    try {
      // Fetch the reservation details before deleting
      DocumentSnapshot reservationDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('recent_reservation_history')
          .doc(reservationId)
          .get();

      if (reservationDoc.exists) {
        Map<String, dynamic> reservationData =
            reservationDoc.data() as Map<String, dynamic>;

        String performedBy =
            FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

        // Delete the reservation history entry
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurantId)
            .collection('recent_reservation_history')
            .doc(reservationId)
            .delete();

        // Log the deletion
        await _logActivity('Delete Reservation History Entry', {
          'ID': reservationId,
          'Customer': reservationData['reservationData']['userEmail'],
          'Guests': reservationData['reservationData']['guestCount'],
          'Date/Time': DateFormat('MM/dd/yy h:mm a').format(
              (reservationData['reservationData']['reservationDateTime']
                      as Timestamp)
                  .toDate()),
          'Status': reservationData['reservationData']['status'],
          'Performed By': performedBy
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Reservation history entry deleted successfully by $performedBy'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Reservation history entry not found');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting reservation history entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
