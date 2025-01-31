import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class RecentActivityPage extends StatefulWidget {
  final String restaurantId;

  const RecentActivityPage({super.key, required this.restaurantId});

  @override
  _RecentActivityPageState createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAscending = false;
  String _selectedLogType = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 24),
            _buildSearchAndFilterBar(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildActivityList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: Icon(Icons.search, color: Colors.orange[400]),
              filled: true,
              fillColor: Colors.orange[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _selectedLogType,
          items: [
            'All',
            'Menu',
            'Reservation',
            'Reservation History',
            'Login',
            'Logout'
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLogType = newValue!;
            });
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
          onPressed: () {
            setState(() {
              _isAscending = !_isAscending;
            });
          },
          tooltip: _isAscending ? 'Sort Ascending' : 'Sort Descending',
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getActivityStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orange));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No activities found.'));
        }

        var activities = snapshot.data!;
        activities = _filterAndSortActivities(activities);

        return ListView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return ActivityItem(activity: activities[index]);
          },
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getActivityStream() {
    var firestore = FirebaseFirestore.instance;

    Stream<QuerySnapshot> menuStream = firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('menu_logs')
        .snapshots();

    Stream<QuerySnapshot> reservationStream = firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('reservation_page_logs')
        .snapshots();

    Stream<QuerySnapshot> customerStream = firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('reservation_history_page_logs')
        .snapshots();

    Stream<QuerySnapshot> loginStream = firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('login_logs')
        .snapshots();

    Stream<QuerySnapshot> logoutStream = firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('logout_logs')
        .snapshots();

    return Rx.combineLatest5(
      menuStream,
      reservationStream,
      customerStream,
      loginStream,
      logoutStream,
      (QuerySnapshot menuSnapshot,
          QuerySnapshot reservationSnapshot,
          QuerySnapshot customerSnapshot,
          QuerySnapshot loginSnapshot,
          QuerySnapshot logoutSnapshot) {
        List<Map<String, dynamic>> allActivities = [];

        if (_selectedLogType == 'All' || _selectedLogType == 'Menu') {
          allActivities.addAll(menuSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>));
        }
        if (_selectedLogType == 'All' || _selectedLogType == 'Reservation') {
          allActivities.addAll(reservationSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>));
        }
        if (_selectedLogType == 'All' ||
            _selectedLogType == 'Reservation History') {
          allActivities.addAll(customerSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>));
        }
        if (_selectedLogType == 'All' || _selectedLogType == 'Login') {
          allActivities.addAll(loginSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>));
        }
        if (_selectedLogType == 'All' || _selectedLogType == 'Logout') {
          allActivities.addAll(logoutSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>));
        }

        return allActivities;
      },
    );
  }

  List<Map<String, dynamic>> _filterAndSortActivities(
      List<Map<String, dynamic>> activities) {
    var filteredActivities = activities.where((activity) {
      var searchTerm = _searchController.text.toLowerCase();
      String actionStr = activity['action']?.toString() ?? '';
      String detailsStr = _getDetailsString(activity);
      String performedByStr = activity['performedBy']?.toString() ?? '';
      String emailStr = activity['email']?.toString() ??
          activity['userEmail']?.toString() ??
          '';

      return actionStr.toLowerCase().contains(searchTerm) ||
          detailsStr.toLowerCase().contains(searchTerm) ||
          performedByStr.toLowerCase().contains(searchTerm) ||
          emailStr.toLowerCase().contains(searchTerm);
    }).toList();

    filteredActivities.sort((a, b) {
      var aTimestamp = a['timestamp'];
      var bTimestamp = b['timestamp'];
      if (aTimestamp == null || bTimestamp == null) return 0;

      DateTime aDateTime = _parseTimestamp(aTimestamp);
      DateTime bDateTime = _parseTimestamp(bTimestamp);

      return _isAscending
          ? aDateTime.compareTo(bDateTime)
          : bDateTime.compareTo(aDateTime);
    });

    return filteredActivities;
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      if (timestamp.contains('seconds=')) {
        final regex = RegExp(r'seconds=(\d+)');
        final match = regex.firstMatch(timestamp);
        if (match != null) {
          final seconds = int.parse(match.group(1)!);
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } else {
        // Attempt to parse the string directly
        final parsedDate = DateTime.tryParse(timestamp);
        if (parsedDate != null) {
          return parsedDate;
        }
      }
    }
    return DateTime.now(); // Default to current time if parsing fails
  }

  String _getDetailsString(Map<String, dynamic> activity) {
    var details = activity['details'] ?? '';
    if (details is Map) {
      if (details.containsKey('itemData')) {
        var itemData = details['itemData'] as Map;
        return '${itemData['name']} - ${itemData['price']} - ${itemData['description']}';
      } else if (details.containsKey('oldData') &&
          details.containsKey('newData')) {
        var newData = details['newData'] as Map;
        return '${newData['name']} - ${newData['price']} - ${newData['description']}';
      }
    }
    return details.toString();
  }
}

class ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    activity['action'] ?? 'Unknown Action',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                Text(
                  _formatTimestamp(activity['timestamp']),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._getActivityDetails(),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Time';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      if (timestamp.contains('seconds=')) {
        final regex = RegExp(r'seconds=(\d+)');
        final match = regex.firstMatch(timestamp);
        if (match != null) {
          final seconds = int.parse(match.group(1)!);
          dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        } else {
          return 'Invalid Date';
        }
      } else {
        // Attempt to parse the string directly
        dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
      }
    } else {
      return 'Invalid Date';
    }

    return DateFormat('MM/dd/yyyy hh:mm a').format(dateTime);
  }

  String _formatReservationDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    if (timestamp is Timestamp) {
      return DateFormat('MM/dd/yyyy hh:mm a').format(timestamp.toDate());
    } else if (timestamp is String) {
      if (timestamp.contains('seconds=')) {
        final regex = RegExp(r'seconds=(\d+)');
        final match = regex.firstMatch(timestamp);
        if (match != null) {
          final seconds = int.parse(match.group(1)!);
          final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          return DateFormat('MM/dd/yyyy hh:mm a').format(dateTime);
        }
      } else {
        // Attempt to parse the string directly
        final dateTime = DateTime.tryParse(timestamp);
        if (dateTime != null) {
          return DateFormat('MM/dd/yyyy hh:mm a').format(dateTime);
        }
      }
    }
    return timestamp.toString();
  }

  List<Widget> _getActivityDetails() {
    switch (activity['action']) {
      case 'Delete Menu Item':
        return _getDeleteMenuItemDetails();
      case 'Edit Menu Item':
        return _getEditMenuItemDetails();
      case 'Add Menu Item':
        return _getAddMenuItemDetails();
      case 'Update Status':
        return _getUpdateStatusDetails();
      case 'Delete Reservation':
        return _getDeleteReservationDetails();
      case 'Delete Reservation History Entry':
        return _getReservationHistoryDetails();
      case 'Login':
      case 'Logout':
        return _getLoginLogoutDetails();
      default:
        return _getDefaultDetails();
    }
  }

  List<Widget> _getDeleteMenuItemDetails() {
    var details = activity['details'] as Map;
    var deletedData = details['deletedData'] as Map;
    return [
      Text('Deleted Item Details:',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      Text('Name: ${deletedData['name']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Price: PHP ${deletedData['price']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Description: ${deletedData['description']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Type: ${deletedData['type']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Item ID: ${details['itemId']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Performed by: ${activity['performedBy'] ?? 'Unknown'}',
          style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic)),
    ];
  }

  List<Widget> _getEditMenuItemDetails() {
    var details = activity['details'] as Map;
    var oldData = details['oldData'] as Map;
    var newData = details['newData'] as Map;
    return [
      Text('Edited Item Details:',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      Text('Name: ${oldData['name']} → ${newData['name']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Price: PHP ${oldData['price']} → PHP ${newData['price']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Description: ${oldData['description']} → ${newData['description']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Type: ${oldData['type']} → ${newData['type']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Item ID: ${details['itemId']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Performed by: ${activity['performedBy'] ?? 'Unknown'}',
          style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic)),
    ];
  }

  List<Widget> _getAddMenuItemDetails() {
    var details = activity['details'] as Map;
    var itemData = details['itemData'] as Map;
    return [
      Text('Added Item Details:',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      Text('Name: ${itemData['name']}', style: GoogleFonts.inter(fontSize: 14)),
      Text('Price: PHP ${itemData['price']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Description: ${itemData['description']}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Type: ${itemData['type']}', style: GoogleFonts.inter(fontSize: 14)),
      Text('Performed by: ${activity['performedBy'] ?? 'Unknown'}',
          style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic)),
    ];
  }

  List<Widget> _getUpdateStatusDetails() {
    return [
      Text(
        'Update Status Details:',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Set text color to black
        ),
      ),
      const SizedBox(height: 8),
      Text('Reservation ID: ${activity['reservationId'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('User Email: ${activity['userEmail'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Total Payment: PHP ${activity['totalPayment'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Guest Count: ${activity['guestCount'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text(
          'Reservation Date & Time: ${_formatReservationDateTime(activity['reservationDateTime'])}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Payment Method: ${activity['paymentMethod'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Reference Number: ${activity['referenceNumber'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('New Status: ${activity['status'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      const SizedBox(height: 4),
      Text('Performed By: ${activity['performedBy'] ?? 'Unknown'}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey[700],
          )),
    ];
  }

  List<Widget> _getDeleteReservationDetails() {
    return [
      Text(
        'Deleted Reservation Details:',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Set text color to black
        ),
      ),
      const SizedBox(height: 8),
      Text('Reservation ID: ${activity['reservationId'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('User Email: ${activity['userEmail'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Total Payment: PHP ${activity['totalPayment'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Guest Count: ${activity['guestCount'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text(
          'Reservation Date & Time: ${_formatReservationDateTime(activity['reservationDateTime'])}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Payment Method: ${activity['paymentMethod'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('Reference Number: ${activity['referenceNumber'] ?? 'N/A'}',
          style: GoogleFonts.inter(fontSize: 14)),
      const SizedBox(height: 4),
      Text('Performed By: ${activity['performedBy'] ?? 'Unknown'}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey[700],
          )),
    ];
  }

  List<Widget> _getDeleteHistoryReservationDetails() {
    final detailsString = activity['details'] as String;

    // Split the details by commas and clean up the text
    final List<String> details = detailsString
        .replaceFirst('Deleted reservation history entry:', '')
        .split(',')
        .map((s) => s.trim())
        .toList();

    return [
      Text(
        'Deleted reservation history entry:',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      ...details.map((detail) {
        if (detail.startsWith('Performed By:')) {
          return Text(
            detail,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          );
        }
        return Text(
          detail,
          style: GoogleFonts.inter(fontSize: 14),
        );
      }),
    ];
  }

  List<Widget> _getReservationHistoryDetails() {
    final details = activity['details'] as Map<String, dynamic>;

    // Extract "Performed By" separately, if present
    final performedBy = details.containsKey('Performed By')
        ? Text(
            'Performed By: ${details['Performed By']}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          )
        : null;

    return [
      Text(
        'Reservation History Details:',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      ...details.entries
          .where((entry) => entry.key != 'Performed By')
          .map((entry) {
        return Text(
          '${entry.key}: ${entry.value}',
          style: GoogleFonts.inter(fontSize: 14),
        );
      }),
      if (performedBy != null) performedBy, // Add "Performed By" at the bottom
    ];
  }

  List<Widget> _getLoginLogoutDetails() {
    return [
      Text('Email: ${activity['email'] ?? activity['userEmail'] ?? 'Unknown'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text('User ID: ${activity['userId'] ?? 'Unknown'}',
          style: GoogleFonts.inter(fontSize: 14)),
      Text(
          'Performed by: ${activity['performedBy'] ?? activity['email'] ?? activity['userEmail'] ?? 'Unknown'}',
          style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic)),
    ];
  }

  List<Widget> _getDefaultDetails() {
    if (activity['details'] is String) {
      return [
        Text(
          activity['details'] ?? '',
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ];
    } else if (activity['details'] is Map) {
      return (activity['details'] as Map).entries.map((entry) {
        return Text('${entry.key}: ${entry.value}',
            style: GoogleFonts.inter(fontSize: 14));
      }).toList();
    }
    return [
      Text('No additional details available.',
          style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic)),
    ];
  }
}
