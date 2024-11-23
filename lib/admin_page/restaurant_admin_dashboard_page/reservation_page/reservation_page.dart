import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReservationPage extends StatefulWidget {
  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reservation Management',
                style: GoogleFonts.inter(
                  fontSize: 20, // Slightly smaller font size
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                width: 250, // Reduced width for search field
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reservations...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16), // Reduced spacing
          Expanded(
            child: ListView(
              children: [
                _buildReservationSection(
                  'Pending Reservations',
                  [
                    _ReservationData(
                      id: '3',
                      customerName: 'Danyel Rodriguez',
                      orderId: '3',
                      guests: '5',
                      payment: 'GCash',
                      dateTime: DateTime.now(),
                      message: 'No Peanut',
                      refNum: '781 888 1893',
                      status: ReservationStatus.pending,
                    ),
                  ],
                  Colors.orange,
                ),
                SizedBox(height: 16), // Reduced spacing
                _buildReservationSection(
                  'Approved Reservations',
                  [
                    _ReservationData(
                      id: '2',
                      customerName: 'John Troller',
                      orderId: '2',
                      guests: '7',
                      payment: 'GCash',
                      dateTime: DateTime.now(),
                      message: 'None',
                      refNum: '123 654 0032',
                      status: ReservationStatus.approved,
                    ),
                  ],
                  Colors.green,
                ),
                SizedBox(height: 16), // Reduced spacing
                _buildReservationSection(
                  'Complete Reservations',
                  [
                    _ReservationData(
                      id: '1',
                      customerName: 'Bryan Agel',
                      orderId: '1',
                      guests: '7',
                      payment: 'GCash',
                      dateTime: DateTime.now(),
                      message: 'Add extra 1 rice',
                      refNum: '321 212 8549',
                      status: ReservationStatus.completed,
                    ),
                  ],
                  Colors.blue,
                ),
                SizedBox(height: 16), // Reduced spacing
                _buildReservationSection(
                  'Cancelled Reservations',
                  [
                    _ReservationData(
                      id: '4',
                      customerName: 'Lara Croft',
                      orderId: '4',
                      guests: '2',
                      payment: 'Credit Card',
                      dateTime: DateTime.now(),
                      message: 'Family emergency',
                      refNum: '456 789 0123',
                      status: ReservationStatus.cancelled,
                    ),
                  ],
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationSection(
      String title,
      List<_ReservationData> reservations,
      Color accentColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0), // Reduced padding
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16, // Slightly smaller font size
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
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
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Guests')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Date/Time')),
                DataColumn(label: Text('Message')),
                DataColumn(label: Text('Ref. Number')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: reservations.map((reservation) {
                return DataRow(
                  cells: [
                    DataCell(Text(reservation.id)),
                    DataCell(Text(reservation.customerName)),
                    DataCell(Text(reservation.orderId)),
                    DataCell(Text(reservation.guests)),
                    DataCell(Text(reservation.payment)),
                    DataCell(Text(DateFormat('MM/dd/yy HH:mm').format(reservation.dateTime))),
                    DataCell(Text(reservation.message)),
                    DataCell(Text(reservation.refNum)),
                    DataCell(_buildStatusBadge(reservation.status, accentColor)),
                    DataCell(_buildActionButtons(reservation.status)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReservationStatus status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toString().split('.').last,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12, // Smaller font size
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReservationStatus status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == ReservationStatus.pending) ...[
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () {
              // Approve logic
            },
            tooltip: 'Approve',
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: Colors.red),
            onPressed: () {
              // Reject logic
            },
            tooltip: 'Reject',
          ),
        ] else if (status == ReservationStatus.approved) ...[
          IconButton(
            icon: Icon(Icons.check_circle, color: Colors.blue),
            onPressed: () {
              // Complete logic
            },
            tooltip: 'Complete',
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              // Cancel logic
            },
            tooltip: 'Cancel',
          ),
        ] else if (status == ReservationStatus.completed) ...[
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () {
              // Mark as completed logic (or similar)
            },
            tooltip: 'Completed',
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              // Cancel logic
            },
            tooltip: 'Cancel',
          ),
        ] else if (status == ReservationStatus.cancelled) ...[
          IconButton(
            icon: Icon(Icons.restore, color: Colors.blue),
            onPressed: () {
              // Restore logic
            },
            tooltip: 'Restore',
          ),
        ],
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onPressed: () {
            // More actions
          },
          tooltip: 'More',
        ),
      ],
    );
  }
}

enum ReservationStatus {
  pending,
  approved,
  completed,
  cancelled,
}

class _ReservationData {
  final String id;
  final String customerName;
  final String orderId;
  final String guests;
  final String payment;
  final DateTime dateTime;
  final String message;
  final String refNum;
  final ReservationStatus status;

  _ReservationData({
    required this.id,
    required this.customerName,
    required this.orderId,
    required this.guests,
    required this.payment,
    required this.dateTime,
    required this.message,
    required this.refNum,
    required this.status,
  });
}