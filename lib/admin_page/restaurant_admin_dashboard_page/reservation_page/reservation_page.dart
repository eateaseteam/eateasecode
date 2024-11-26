import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../android_users/HomePage/RestaurantPage/restaurant_data_manager.dart';

class ReservationPage extends StatefulWidget {
  final String restaurantId;

  const ReservationPage({Key? key, required this.restaurantId}) : super(key: key);

  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final RestaurantDataManager _restaurantDataManager = RestaurantDataManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: Text('Reservation Management', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: ReservationSearchDelegate(widget.restaurantId),
                    );
                  },
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _restaurantDataManager.getReservationsStream(widget.restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(child: Center(child: Text('No reservations found.')));
                }

                final reservations = snapshot.data!.docs;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildReservationSection('Pending', reservations.where((doc) => doc['status'] == 'pending').toList(), Colors.orange),
                    _buildReservationSection('Approved', reservations.where((doc) => doc['status'] == 'approved').toList(), Colors.green),
                    _buildReservationSection('Complete', reservations.where((doc) => doc['status'] == 'completed').toList(), Colors.blue),
                    _buildReservationSection('Cancelled', reservations.where((doc) => doc['status'] == 'cancelled').toList(), Colors.red),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationSection(String title, List<QueryDocumentSnapshot> reservations, Color accentColor) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '$title Reservations',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Customer Email')),
                DataColumn(label: Text('Order Details')),
                DataColumn(label: Text('Guests')),
                DataColumn(label: Text('Date/Time')),
                DataColumn(label: Text('Total Price')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Ref. Number')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: reservations.map((reservation) {
                final data = reservation.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(data['userEmail'] ?? 'N/A')),
                    DataCell(_buildOrderDetails(data['items'] ?? [])),
                    DataCell(Text(data['guestCount'].toString())),
                    DataCell(Text(DateFormat('MM/dd HH:mm').format((data['reservationDateTime'] as Timestamp).toDate()))),
                    DataCell(Text('PHP ${data['totalPrice'].toStringAsFixed(2)}')),
                    DataCell(Text(data['paymentMethod'] ?? 'N/A')),
                    DataCell(Text(data['referenceNumber'] ?? 'N/A')),
                    DataCell(_buildStatusBadge(data['status'], accentColor)),
                    DataCell(_buildActionButtons(data['status'], reservation.id)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(List<dynamic> items) {
    return Container(
      constraints: BoxConstraints(maxWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Text('${item['name']} x ${item['quantity']}', overflow: TextOverflow.ellipsis);
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButtons(String status, String reservationId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'pending') ...[
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _updateReservationStatus(reservationId, 'approved'),
            tooltip: 'Approve',
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: Colors.red),
            onPressed: () => _updateReservationStatus(reservationId, 'cancelled'),
            tooltip: 'Cancel',
          ),
        ] else if (status == 'approved') ...[
          IconButton(
            icon: Icon(Icons.check_circle, color: Colors.blue),
            onPressed: () => _updateReservationStatus(reservationId, 'completed'),
            tooltip: 'Complete',
          ),
        ],
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onPressed: () {
            // Implement more actions if needed
          },
          tooltip: 'More',
        ),
      ],
    );
  }

  void _updateReservationStatus(String reservationId, String newStatus) async {
    try {
      await _restaurantDataManager.updateReservationStatus(widget.restaurantId, reservationId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reservation status: $e')),
      );
    }
  }
}

class ReservationSearchDelegate extends SearchDelegate {
  final String restaurantId;
  final RestaurantDataManager _restaurantDataManager = RestaurantDataManager();

  ReservationSearchDelegate(this.restaurantId);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _restaurantDataManager.getReservationsStream(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No reservations found.'));
        }

        final reservations = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userEmail'].toString().toLowerCase().contains(query.toLowerCase()) ||
              data['referenceNumber'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final data = reservations[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['userEmail'] ?? 'N/A'),
              subtitle: Text(DateFormat('MM/dd HH:mm').format((data['reservationDateTime'] as Timestamp).toDate())),
              trailing: Text(data['status']),
            );
          },
        );
      },
    );
  }
}