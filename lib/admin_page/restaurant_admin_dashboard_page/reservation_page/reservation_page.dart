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
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            StreamBuilder<QuerySnapshot>(
              stream: _restaurantDataManager.getReservationsStream(widget.restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No reservations found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final reservations = snapshot.data!.docs;
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildReservationSection(
                      'Pending',
                      reservations.where((doc) => doc['status'] == 'pending').toList(),
                      Colors.orange,
                    ),
                    _buildReservationSection(
                      'Approved',
                      reservations.where((doc) => doc['status'] == 'approved').toList(),
                      Colors.green,
                    ),
                    _buildReservationSection(
                      'Complete',
                      reservations.where((doc) => doc['status'] == 'completed').toList(),
                      Colors.blue,
                    ),
                    _buildReservationSection(
                      'Cancelled',
                      reservations.where((doc) => doc['status'] == 'cancelled').toList(),
                      Colors.red,
                    ),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 2,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(
        'Reservation Management',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.black87),
          onPressed: () {
            showSearch(
              context: context,
              delegate: ReservationSearchDelegate(
                widget.restaurantId,
                context,
                _showReservationDetails,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReservationSection(
      String title,
      List<QueryDocumentSnapshot> reservations,
      Color accentColor,
      ) {
    if (reservations.isEmpty) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '$title Reservations',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reservations.length}',
                    style: GoogleFonts.inter(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 16,
                columnSpacing: 24,
                headingRowHeight: 48,
                dataRowHeight: 72,
                headingTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
                      DataCell(Text(
                        data['userEmail'] ?? 'N/A',
                        style: GoogleFonts.inter(),
                      )),
                      DataCell(_buildOrderDetails(data['items'] ?? [])),
                      DataCell(Text(
                        data['guestCount'].toString(),
                        style: GoogleFonts.inter(),
                      )),
                      DataCell(Text(
                        DateFormat('MM/dd h:mm a')
                            .format((data['reservationDateTime'] as Timestamp).toDate()),
                        style: GoogleFonts.inter(),
                      )),
                      DataCell(Text(
                        'PHP ${data['totalPrice'].toStringAsFixed(2)}',
                        style: GoogleFonts.inter(),
                      )),
                      DataCell(Text(
                        data['paymentMethod'] ?? 'N/A',
                        style: GoogleFonts.inter(),
                      )),
                      DataCell(Text(
                        data['referenceNumber'] ?? 'N/A',
                        style: GoogleFonts.inter(),
                      )),
                      DataCell(_buildStatusBadge(data['status'], accentColor)),
                      DataCell(_buildActionButtons(data['status'], reservation.id, data)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(List<dynamic> items) {
    return PopupMenuButton<void>(
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${item['name']} x ${item['quantity']}',
                  style: GoogleFonts.inter(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
      child: Container(
        constraints: BoxConstraints(maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                items.map((item) => '${item['name']} x ${item['quantity']}').join(', '),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status, String reservationId, Map<String, dynamic> data) {
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
          icon: Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDeleteReservation(reservationId),
          tooltip: 'Delete',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (value) async {
            switch (value) {
              case 'view':
                _showReservationDetails(data);
                break;
              case 'delete':
                _confirmDeleteReservation(reservationId);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 20, color: Colors.black87),
                  SizedBox(width: 8),
                  Text('View Details', style: GoogleFonts.inter()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: GoogleFonts.inter()),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDeleteReservation(String reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Deletion',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this reservation? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showReservationDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reservation Details',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(height: 32),
                _buildDetailRow('Customer', data['userEmail'] ?? 'N/A'),
                _buildDetailRow('Reference Number', data['referenceNumber'] ?? 'N/A'),
                _buildDetailRow('Date/Time',
                    DateFormat('MM/dd/yy h:mm a').format((data['reservationDateTime'] as Timestamp).toDate())),
                _buildDetailRow('Guests', '${data['guestCount']}'),
                _buildDetailRow('Payment Method', data['paymentMethod'] ?? 'N/A'),
                _buildDetailRow('Total Price', 'PHP ${data['totalPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                SizedBox(height: 16),
                Text(
                  'Order Items',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ...(data['items'] as List<dynamic>).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                      Text(
                        'x${item['quantity']}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
                SizedBox(height: 16),
                Text(
                  'Order Notes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['orderNotes'] ?? 'No order notes',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
                if ((data['notes'] ?? '').isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Notes',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['notes'],
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
                if (data['status'] == 'cancelled') ...[
                  SizedBox(height: 16),
                  Text(
                    'Cancellation Reason',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['cancellationReason'] ?? 'No reason provided',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(String reservationId, String currentNotes) {
    final TextEditingController notesController = TextEditingController(text: currentNotes);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reservation Notes',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add notes here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('restaurants')
                            .doc(widget.restaurantId)
                            .collection('reservations')
                            .doc(reservationId)
                            .update({'notes': notesController.text});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Notes updated successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating notes: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Save Notes',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateReservationStatus(String reservationId, String newStatus) {
    String actionText = '';
    switch (newStatus) {
      case 'approved':
        actionText = 'approve';
        break;
      case 'cancelled':
        actionText = 'cancel';
        break;
      case 'completed':
        actionText = 'mark as completed';
        break;
      default:
        actionText = 'update';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Action',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to $actionText this reservation?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _restaurantDataManager.updateReservationStatus(
                    widget.restaurantId, reservationId, newStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reservation status updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update reservation status: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActionColor(newStatus),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getActionColor(String status) {
  switch (status) {
    case 'approved':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'completed':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

class ReservationSearchDelegate extends SearchDelegate {
  final String restaurantId;
  final RestaurantDataManager _restaurantDataManager = RestaurantDataManager();
  final BuildContext parentContext;
  final Function(Map<String, dynamic>) showReservationDetails;

  ReservationSearchDelegate(this.restaurantId, this.parentContext, this.showReservationDetails);

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
              subtitle: Text(DateFormat('MM/dd h:mm a').format((data['reservationDateTime'] as Timestamp).toDate())),
              trailing: Text(data['status']),
              onTap: () {
                close(context, null);
                showReservationDetails(data);
              },
            );
          },
        );
      },
    );
  }
}

