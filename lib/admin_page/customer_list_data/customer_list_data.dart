import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerListPage extends StatefulWidget {
  @override
  _CustomerListPageState createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _customers = [
    {
      'id': 1,
      'lastName': 'Smith',
      'firstName': 'John',
      'email': 'john.smith@example.com',
      'password': '••••••••'
    },
    {
      'id': 2,
      'lastName': 'Johnson',
      'firstName': 'Emma',
      'email': 'emma.j@example.com',
      'password': '••••••••'
    },
    {
      'id': 3,
      'lastName': 'Williams',
      'firstName': 'Michael',
      'email': 'm.williams@example.com',
      'password': '••••••••'
    },
  ];

  List<Map<String, dynamic>> get _filteredCustomers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      return customer['lastName'].toLowerCase().contains(query) ||
          customer['firstName'].toLowerCase().contains(query) ||
          customer['email'].toLowerCase().contains(query);
    }).toList();
  }

  void _deleteCustomer(int id) {
    setState(() {
      _customers.removeWhere((customer) => customer['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Customer\'s Data',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
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
            SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Color(0xFF2D3748),
                      ),
                      headingTextStyle: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      columns: [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Last Name')),
                        DataColumn(label: Text('First Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Password')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredCustomers.map((customer) {
                        return DataRow(
                          cells: [
                            DataCell(Text(
                              customer['id'].toString(),
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(Text(
                              customer['lastName'],
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(Text(
                              customer['firstName'],
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(Text(
                              customer['email'],
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(Text(
                              customer['password'],
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(
                              TextButton.icon(
                                icon: Icon(Icons.delete, size: 18),
                                label: Text('Delete'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'Confirm Deletion',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this customer?',
                                        style: GoogleFonts.inter(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.inter(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _deleteCustomer(customer['id']);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.red[600],
                                          ),
                                          child: Text(
                                            'Delete',
                                            style: GoogleFonts.inter(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red[600],
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
            ),
          ],
        ),
      ),
    );
  }
}