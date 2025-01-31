import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NotificationScreen({super.key});

  Stream<List<DocumentSnapshot>> _getNotifications() {
    final userId = _auth.currentUser!.uid;
    return _firestore
        .collectionGroup('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('reservationDateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Widget _buildNotificationCard(
      BuildContext context, DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final restaurantName =
        data['restaurantName'] as String? ?? 'Unknown Restaurant';
    final reservationDateTime =
        (data['reservationDateTime'] as Timestamp).toDate();
    final status = data['status'] as String? ?? 'pending';
    final totalPrice = data['totalPrice'] as double? ?? 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showNotificationDetails(context, document),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      restaurantName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMMM d, y - h:mm a').format(reservationDateTime),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PHP ${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeago.format(reservationDateTime),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;

    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      case 'pending':
        chipColor = Colors.orange;
        chipIcon = Icons.access_time;
        break;
      default:
        chipColor = Colors.blue;
        chipIcon = Icons.info;
    }

    return Chip(
      label: Text(
        status.capitalize(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor,
      avatar: Icon(chipIcon, color: Colors.white, size: 16),
    );
  }

  void _showNotificationDetails(
      BuildContext context, DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservation Details',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'Restaurant', data['restaurantName'] ?? 'Unknown'),
                  _buildDetailRow(
                      'Date',
                      DateFormat('MMMM d, y').format(
                          (data['reservationDateTime'] as Timestamp).toDate())),
                  _buildDetailRow(
                      'Time',
                      DateFormat('h:mm a').format(
                          (data['reservationDateTime'] as Timestamp).toDate())),
                  _buildDetailRow('Status',
                      (data['status'] as String?)?.capitalize() ?? 'Unknown'),
                  _buildDetailRow(
                      'Guests', (data['guestCount'] ?? 0).toString()),
                  _buildDetailRow('Total Price',
                      'PHP ${(data['totalPrice'] as double?)?.toStringAsFixed(2) ?? '0.00'}'),
                  const SizedBox(height: 16),
                  Text(
                    'Order Items',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildOrderItems(data['items'] as List<dynamic>? ?? []),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItems(List<dynamic> items) {
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item['name'],
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              'x${item['quantity']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No notifications',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(context, snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
