import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  _CustomerListPageState createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference _customersCollection = FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> _getCustomers() {
    return _customersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'lastName': data['lastName'] ?? '',
          'firstName': data['firstName'] ?? '',
          'email': data['email'] ?? '',
          'createdAt': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();
    });
  }

  Future<void> _logActivity(String action, String details) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(currentUserId)
            .collection('customer_list_data_logs') // Changed to customer_list_data_logs
            .add({
          'action': action,
          'details': details,
          'timestamp': FieldValue.serverTimestamp(),
          'performedBy': _auth.currentUser?.email ?? 'Unknown',
        });
      }
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<void> _deleteCustomer(String id, String firstName, String lastName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete $firstName $lastName?', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.red[600]),
              child: Text('Delete', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await _customersCollection.doc(id).delete();
        await _logActivity('Delete Customer', 'Deleted customer: $firstName $lastName (ID: $id)');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$firstName $lastName has been deleted.'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting customer: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Customer Data',
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    if (!isSmallScreen) _buildSearchField(),
                  ],
                ),
                const SizedBox(height: 16),
                if (isSmallScreen) _buildSearchField(),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _getCustomers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final customers = snapshot.data!;
                      final filteredCustomers = _filterCustomers(customers);

                      return _buildCustomerTable(filteredCustomers, isSmallScreen);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  List<Map<String, dynamic>> _filterCustomers(List<Map<String, dynamic>> customers) {
    final query = _searchController.text.toLowerCase();
    return customers.where((customer) {
      return customer['lastName'].toLowerCase().contains(query) ||
          customer['firstName'].toLowerCase().contains(query) ||
          customer['email'].toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildCustomerTable(List<Map<String, dynamic>> customers, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2D3748)),
              headingTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Last Name')),
                DataColumn(label: Text('First Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Actions')),
              ],
              rows: customers.map((customer) {
                return DataRow(
                  cells: [
                    DataCell(_buildTableCell(customer['id'], isSmallScreen ? 60 : 100)),
                    DataCell(_buildTableCell(customer['lastName'], isSmallScreen ? 80 : 120)),
                    DataCell(_buildTableCell(customer['firstName'], isSmallScreen ? 80 : 120)),
                    DataCell(_buildTableCell(customer['email'], isSmallScreen ? 120 : 160)),
                    DataCell(_buildTableCell(
                      DateFormat('yyyy-MM-dd HH:mm').format((customer['createdAt'] as Timestamp).toDate()),
                      isSmallScreen ? 100 : 140,
                    )),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[600]),
                        onPressed: () => _deleteCustomer(
                          customer['id'],
                          customer['firstName'],
                          customer['lastName'],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter()),
    );
  }
}

