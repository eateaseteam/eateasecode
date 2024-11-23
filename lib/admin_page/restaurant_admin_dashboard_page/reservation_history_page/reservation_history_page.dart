import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReservationHistoryPage extends StatefulWidget {
  @override
  _ReservationHistoryPageState createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation History',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  width: 250,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search history...',
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
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildHistorySection('This Month', _thisMonthReservations),
                  SizedBox(height: 16),
                  _buildHistorySection('Last Month', _lastMonthReservations),
                  SizedBox(height: 16),
                  _buildHistorySection('Older', _olderReservations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(String title, List<_ReservationData> reservations) {
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
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
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
                DataColumn(label: Text('Guests')),
                DataColumn(label: Text('Date/Time')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: reservations.map((reservation) {
                return DataRow(
                  cells: [
                    DataCell(Text(reservation.id)),
                    DataCell(Text(reservation.customerName)),
                    DataCell(Text(reservation.guests)),
                    DataCell(Text(DateFormat('MM/dd/yy HH:mm').format(reservation.dateTime))),
                    DataCell(_buildStatusBadge(reservation.status)),
                    DataCell(_buildActionButtons()),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReservationStatus status) {
    Color color;
    switch (status) {
      case ReservationStatus.completed:
        color = Colors.green;
        break;
      case ReservationStatus.cancelled:
        color = Colors.red;
        break;
      case ReservationStatus.noShow:
        color = Colors.orange;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toString().split('.').last,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.visibility, color: Colors.blue),
          onPressed: () {
            // View details logic
          },
          tooltip: 'View Details',
        ),
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
  completed,
  cancelled,
  noShow,
}

class _ReservationData {
  final String id;
  final String customerName;
  final String guests;
  final DateTime dateTime;
  final ReservationStatus status;

  _ReservationData({
    required this.id,
    required this.customerName,
    required this.guests,
    required this.dateTime,
    required this.status,
  });
}

// Sample data
final List<_ReservationData> _thisMonthReservations = [
  _ReservationData(
    id: '1001',
    customerName: 'John Doe',
    guests: '4',
    dateTime: DateTime.now().subtract(Duration(days: 5)),
    status: ReservationStatus.completed,
  ),
  _ReservationData(
    id: '1002',
    customerName: 'Jane Smith',
    guests: '2',
    dateTime: DateTime.now().subtract(Duration(days: 10)),
    status: ReservationStatus.cancelled,
  ),
];

final List<_ReservationData> _lastMonthReservations = [
  _ReservationData(
    id: '985',
    customerName: 'Alice Johnson',
    guests: '6',
    dateTime: DateTime.now().subtract(Duration(days: 35)),
    status: ReservationStatus.completed,
  ),
  _ReservationData(
    id: '986',
    customerName: 'Bob Williams',
    guests: '3',
    dateTime: DateTime.now().subtract(Duration(days: 40)),
    status: ReservationStatus.noShow,
  ),
];

final List<_ReservationData> _olderReservations = [
  _ReservationData(
    id: '754',
    customerName: 'Charlie Brown',
    guests: '5',
    dateTime: DateTime.now().subtract(Duration(days: 90)),
    status: ReservationStatus.completed,
  ),
  _ReservationData(
    id: '755',
    customerName: 'Diana Prince',
    guests: '2',
    dateTime: DateTime.now().subtract(Duration(days: 95)),
    status: ReservationStatus.completed,
  ),
];