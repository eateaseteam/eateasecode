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
    _tabController = TabController(length: 3, vsync: this);
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
                        _buildRadioOption('Want to book another restaurant', selectedReason, (value) {
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
                      await _firestore.collection('reservations').doc(reservationId).update({
                        'status': 'cancelled',
                        'cancellationReason': reason,
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel Order',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioOption(String title, String? selectedReason, Function(String?) onChanged) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16),
      ),
      value: title,
      groupValue: selectedReason,
      onChanged: onChanged,
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      activeColor: Colors.deepOrange,
    );
  }

  Widget _buildReservationCard(DocumentSnapshot reservation) {
    final data = reservation.data() as Map<String, dynamic>;
    final restaurantName = data['restaurantName'] as String;
    final imagePath = data['imagePath'] as String;
    final dateTime = (data['dateTime'] as Timestamp).toDate();
    final totalPrice = (data['totalPrice'] as num).toDouble();
    final status = data['status'] as String;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
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
            if (status == 'completed')
              Icon(Icons.check_circle, color: Colors.green, size: 28)
            else if (status == 'pending')
              IconButton(
                icon: Icon(Icons.cancel_outlined, color: Colors.deepOrange, size: 28),
                onPressed: () => _showCancelDialog(context, reservation.id),
              ),
          ],
        ),
      ),
    );
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationList('completed'),
          _buildReservationList('pending'),
          _buildReservationList('cancelled'),
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
}