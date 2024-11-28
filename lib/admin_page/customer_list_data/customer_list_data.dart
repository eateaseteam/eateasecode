import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerListPage extends StatefulWidget {
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
        return {
          'id': doc.id,
          'lastName': doc['lastName'],
          'firstName': doc['firstName'],
          'email': doc['email'],
        };
      }).toList();
    });
  }

  void _deleteCustomer(String id, String firstName, String lastName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete $firstName $lastName?', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                _customersCollection.doc(id).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$firstName $lastName has been deleted.')));
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.red[600]),
              child: Text('Delete', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
    );
  }

  void _requestPasswordReset(String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Send Password Reset Link', style: GoogleFonts.inter()),
          content: Text('Send a password reset link to $email?', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _auth.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email.')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.blue[600]),
              child: Text('Send Link', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
    );
  }

  void _editCustomer(Map<String, dynamic> customer) {
    final TextEditingController _firstNameController = TextEditingController(text: customer['firstName']);
    final TextEditingController _lastNameController = TextEditingController(text: customer['lastName']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Customer', style: GoogleFonts.inter()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              Text('Email: ${customer['email']}', style: TextStyle(color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                String updatedFirstName = _firstNameController.text;
                String updatedLastName = _lastNameController.text;
                String updatedFullName = '$updatedFirstName $updatedLastName';

                _customersCollection.doc(customer['id']).update({
                  'firstName': updatedFirstName,
                  'lastName': updatedLastName,
                  'fullName': updatedFullName,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer updated successfully.')));
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green[600]),
              child: Text('Update', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;
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
                    if (!isSmallScreen)
                      Container(
                        width: 300,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                if (isSmallScreen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _getCustomers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final customers = snapshot.data!;
                      final filteredCustomers = customers.where((customer) {
                        final query = _searchController.text.toLowerCase();
                        return customer['lastName'].toLowerCase().contains(query) ||
                            customer['firstName'].toLowerCase().contains(query) ||
                            customer['email'].toLowerCase().contains(query);
                      }).toList();

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Color(0xFF2D3748)),
                              headingTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                              columns: [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Last Name')),
                                DataColumn(label: Text('First Name')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filteredCustomers.map((customer) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: isSmallScreen ? 60 : 100,
                                        child: Text(customer['id'], overflow: TextOverflow.ellipsis, style: GoogleFonts.inter()),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: isSmallScreen ? 80 : 120,
                                        child: Text(customer['lastName'], overflow: TextOverflow.ellipsis, style: GoogleFonts.inter()),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: isSmallScreen ? 80 : 120,
                                        child: Text(customer['firstName'], overflow: TextOverflow.ellipsis, style: GoogleFonts.inter()),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: isSmallScreen ? 120 : 160,
                                        child: Text(customer['email'], overflow: TextOverflow.ellipsis, style: GoogleFonts.inter()),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Colors.blue[600]),
                                            onPressed: () => _editCustomer(customer),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red[600]),
                                            onPressed: () => _deleteCustomer(
                                              customer['id'],
                                              customer['firstName'],
                                              customer['lastName'],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.lock_reset, color: Colors.green[600]),
                                            onPressed: () => _requestPasswordReset(customer['email']),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
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
}
