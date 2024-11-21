import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingDisplayScreen extends StatefulWidget {
  @override
  _BookingDisplayScreenState createState() => _BookingDisplayScreenState();
}

class _BookingDisplayScreenState extends State<BookingDisplayScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getBookings() {
    return _firestore.collection('reservations').snapshots();
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('reservations').doc(bookingId).update({
        'status': newStatus,
        'cancellationReason': newStatus == 'cancelled' ? 'User cancelled the booking' : null,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Widget _buildBookingCard(DocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;
    final bookerName = data['bookerName'] as String? ?? 'Unknown Booker';
    final restaurantName = data['restaurantName'] as String? ?? 'Unknown Restaurant';
    final imagePath = data['imagePath'] as String? ?? 'lib/assets/default_image.png'; // Provide a default image path
    final dateTime = (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(); // Use current time as a fallback
    final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0; // Default to 0.0
    final status = data['status'] as String? ?? 'unknown'; // Provide a default status

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        'Booker: $bookerName',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Restaurant: $restaurantName',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy - h:mm a').format(dateTime),
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total: PHP ${totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Status: $status',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _getStatusColor(status)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending')
                  ElevatedButton(
                    onPressed: () => _updateBookingStatus(booking.id, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Approve'),
                  ),
                SizedBox(width: 8),
                if (status != 'cancelled')
                  ElevatedButton(
                    onPressed: () => _updateBookingStatus(booking.id, 'cancelled'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Cancel'),
                  ),
                SizedBox(width: 8),
                if (status == 'approved')
                  ElevatedButton(
                    onPressed: () => _updateBookingStatus(booking.id, 'pending'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Revert to Pending'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
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
          'Reservation Bookings',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'lib/assets/app_images/official_logo.png',
              height: 40,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching bookings. Please try again.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No bookings available.',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(snapshot.data!.docs[index]);
            },
          );
        },
      ),
    );
  }
}