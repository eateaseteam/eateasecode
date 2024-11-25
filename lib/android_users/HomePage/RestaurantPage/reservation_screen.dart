import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationScreen extends StatefulWidget {
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getReservations(String status) {
    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .where('status', isEqualTo: status)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  Widget _buildReservationCard(DocumentSnapshot reservation) {
    final data = reservation.data() as Map<String, dynamic>;
    final restaurantName = data['restaurantName'] ?? 'Unknown Restaurant';
    final logoUrl = data['logoUrl'] ?? 'https://via.placeholder.com/80';
    final dateTime = (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final status = data['status'] ?? 'pending';
    final reservationId = reservation.id;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationDetailsScreen(reservationId: reservationId),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  logoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'lib/assets/app_images/placeholder.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy - h:mm a').format(dateTime),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PHP ${totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
              if (status == 'completed' || status == 'cancelled' || status == 'approved')
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 28),
                  onPressed: () => _confirmDelete(reservationId),
                )
              else if (status == 'pending')
                IconButton(
                  icon: Icon(Icons.cancel_outlined, color: Colors.deepOrange, size: 28),
                  onPressed: () => _showCancelDialog(context, reservationId),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String reservationId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm Deletion',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this reservation?',
                  style: GoogleFonts.poppins(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _deleteReservation(reservationId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteReservation(String reservationId) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting reservation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Reservations',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          labelStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Completed'),
            Tab(text: 'Pending'),
            Tab(text: 'Cancelled'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationList('completed'),
          _buildReservationList('pending'),
          _buildReservationList('cancelled'),
          _buildReservationList('approved'),
        ],
      ),
    );
  }

  Widget _buildReservationList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReservations(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.deepOrange));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error fetching reservations. Please try again.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $status reservations',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, String reservationId) {
    String? selectedReason;
    TextEditingController otherReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cancel Booking',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please select the reason for cancellation:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        children: [
                          _buildRadioOption('Change in Plans', selectedReason, (value) {
                            setState(() => selectedReason = value);
                          }),
                          _buildRadioOption('Duplicate Booking', selectedReason, (value) {
                            setState(() => selectedReason = value);
                          }),
                          _buildRadioOption('Want to book another', selectedReason, (value) {
                            setState(() => selectedReason = value);
                          }),
                          _buildRadioOption('Book by Mistake', selectedReason, (value) {
                            setState(() => selectedReason = value);
                          }),
                          _buildRadioOption('Others:', selectedReason, (value) {
                            setState(() => selectedReason = value);
                          }),
                          if (selectedReason == 'Others:')
                            Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: TextField(
                                controller: otherReasonController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your reason',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                maxLines: 3,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        String reason = selectedReason == 'Others:' ? otherReasonController.text : selectedReason!;
                        await FirebaseFirestore.instance.collection('reservations').doc(reservationId).update({
                          'status': 'cancelled',
                          'cancellationReason': reason,
                        });

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel Reservation',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioOption(String label, String? selectedReason, Function(String?) onChanged) {
    return Row(
      children: [
        Radio<String>(
          value: label,
          groupValue: selectedReason,
          onChanged: onChanged,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }
}

class ReservationDetailsScreen extends StatelessWidget {
  final String reservationId;

  ReservationDetailsScreen({required this.reservationId});

  Future<DocumentSnapshot> _getReservationDetails() async {
    return await FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getReservationDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Loading...')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text('Error')),
            body: Center(child: Text('Reservation not found')),
          );
        }

        final reservationData = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> items = reservationData['items'] ?? [];
        final restaurantName = reservationData['restaurantName'] ?? 'Unknown Restaurant';
        final logoUrl = reservationData['logoUrl'] ?? 'https://via.placeholder.com/80';
        final dateTime = (reservationData['dateTime'] as Timestamp).toDate();
        final totalPrice = reservationData['totalPrice'].toDouble();
        final status = reservationData['status'] ?? 'pending';

        return Scaffold(
          appBar: AppBar(
            title: Text('Reservation Details'),
            backgroundColor: Colors.deepOrange,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      logoUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  restaurantName,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                _buildInfoRow('Date & Time', DateFormat('MMM d, yyyy - h:mm a').format(dateTime)),
                _buildInfoRow('Status', status.toUpperCase()),
                _buildInfoRow('Total Price', 'PHP ${totalPrice.toStringAsFixed(2)}'),
                SizedBox(height: 24),
                Text(
                  'Ordered Items:',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...items.map((item) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['image'] ?? 'https://via.placeholder.com/50',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(item['name'] ?? 'Unknown Item'),
                      subtitle: Text('Quantity: ${item['quantity']}'),
                      trailing: Text('PHP ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ],
      ),
    );
  }
}