import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  _RecentActivityScreenState createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAscending = false;
  String _selectedLogType = 'All';
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 24),
            _buildSearchAndFilterBar(),
            const SizedBox(height: 24),
            Expanded(child: _buildActivityList()),
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
              prefixIcon: Icon(Icons.search, color: Colors.indigo[400]),
              filled: true,
              fillColor: Colors.indigo[50],
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
          items: ['All', 'Admin', 'Restaurant'].map((String value) {
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
          return const Center(child: CircularProgressIndicator());
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
    return FirebaseFirestore.instance
        .collection('admin_logs')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          'details': data['details'],
          'timestamp': data['timestamp'],
          'performedBy': data['performedBy'],
          'action': data['action'],
          'adminId': data['adminId'],
        };
      }).toList();
    });
  }

  List<Map<String, dynamic>> _filterAndSortActivities(
      List<Map<String, dynamic>> activities) {
    String currentUserId = _auth.currentUser?.uid ?? '';
    var filteredActivities = activities.where((activity) {
      var searchTerm = _searchController.text.toLowerCase();
      return (activity['details']?.toString().toLowerCase() ?? '')
              .contains(searchTerm) ||
          (activity['performedBy']?.toString().toLowerCase() ?? '')
              .contains(searchTerm) ||
          (activity['action']?.toString().toLowerCase() ?? '')
              .contains(searchTerm);
    }).toList();

    if (_selectedLogType == 'Admin') {
      filteredActivities = filteredActivities.where((activity) {
        return activity['action'] == 'Edit Admin' ||
            activity['action'] == 'Delete Admin' ||
            activity['action'] == 'Password Reset' ||
            activity['action'] == 'Add Admin' ||
            activity['action'] == 'Login' ||
            activity['action'] == 'Logout';
      }).toList();
    } else if (_selectedLogType == 'Customer') {
      filteredActivities = filteredActivities.where((activity) {
        return activity['action'] == 'Customer Action' ||
            activity['action'] == 'Add Customer' ||
            activity['action'] == 'Delete Customer';
      }).toList();
    } else if (_selectedLogType == 'Restaurant') {
      filteredActivities = filteredActivities.where((activity) {
        return activity['action'] == 'Add Restaurant' ||
            activity['action'] == 'Edit Restaurant' ||
            activity['action'] == 'Delete Restaurant' ||
            activity['action'] == 'Password Reset';
      }).toList();
    }

    filteredActivities.sort((a, b) {
      var aTimestamp = a['timestamp'] as Timestamp?;
      var bTimestamp = b['timestamp'] as Timestamp?;

      if (aTimestamp == null) return 1; // Treat null as later
      if (bTimestamp == null) return -1; // Treat null as later

      return _isAscending
          ? aTimestamp.toDate().compareTo(bTimestamp.toDate())
          : bTimestamp.toDate().compareTo(aTimestamp.toDate());
    });

    return filteredActivities;
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
                      color: _getActionColor(activity['action']),
                    ),
                  ),
                ),
                Text(
                  _formatTimestamp(activity['timestamp'] as Timestamp?),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailsWidget(activity['details']),
            const SizedBox(height: 8),
            Text(
              'Performed by: ${activity['performedBy'] ?? 'Unknown'}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsWidget(dynamic details) {
    if (details is Map<String, dynamic>) {
      // Define the order of fields for restaurant details
      final orderOfFields = [
        'owner',
        'name',
        'email',
        'address',
        'phoneNumber',
        'about'
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: orderOfFields
            .where((field) =>
                details.containsKey(field) &&
                !['logoUrl', 'disabled', 'uid'].contains(field))
            .map((field) {
          var value = details[field];
          // Special handling for createdAt
          if (field == 'createdAt' && value is Timestamp) {
            value = DateFormat('MMM dd, yyyy h:mm a').format(value.toDate());
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              '$field: $value',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          );
        }).toList(),
      );
    } else {
      return Text(
        'Details: ${details ?? 'No details provided.'}',
        style: GoogleFonts.inter(fontSize: 14),
      );
    }
  }

  Color _getActionColor(String? action) {
    switch (action) {
      case 'Login':
        return Colors.green;
      case 'Logout':
        return Colors.red;
      case 'Edit Admin':
      case 'Add Admin':
      case 'Password Reset':
        return Colors.blue;
      case 'Delete Admin':
      case 'Delete Customer':
        return Colors.red;
      case 'Add Restaurant':
      case 'Edit Restaurant':
      case 'Delete Restaurant':
        return Colors.orange; // Color for restaurant actions
      default:
        return Colors.black;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('MMM dd, yyyy h:mm a').format(timestamp.toDate());
  }
}
