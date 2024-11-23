import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _admins = [
    {
      'id': 1,
      'username': 'admin1',
      'email': 'admin1@example.com',
      'password': '••••••••'
    },
    {
      'id': 2,
      'username': 'admin2',
      'email': 'admin2@example.com',
      'password': '••••••••'
    },
    {
      'id': 3,
      'username': 'admin3',
      'email': 'admin3@example.com',
      'password': '••••••••'
    },
  ];

  void _addNewAdmin(String username, String email, String password) {
    setState(() {
      _admins.add({
        'id': _admins.length + 1,
        'username': username,
        'email': email,
        'password': '••••••••',
      });
    });
  }

  List<Map<String, dynamic>> get _filteredAdmins {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _admins;

    return _admins.where((admin) {
      return admin['username'].toLowerCase().contains(query) ||
          admin['email'].toLowerCase().contains(query);
    }).toList();
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
                  'Admin Data',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _showAddAdminDialog(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Add New Admin',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
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
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Password')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredAdmins.map((admin) {
                        return DataRow(
                          cells: [
                            DataCell(Text(
                              admin['id'].toString(),
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(Text(
                              admin['username'],
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(Text(
                              admin['email'],
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(Text(
                              admin['password'],
                              style: GoogleFonts.inter(),
                            )),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(Icons.edit, size: 18),
                                    label: Text('Edit'),
                                    onPressed: () {
                                      // Edit logic
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue[600],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: Icon(Icons.delete, size: 18),
                                    label: Text('Delete'),
                                    onPressed: () {
                                      // Delete logic
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red[600],
                                    ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _username = '';
    String _email = '';
    String _password = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Admin',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        content: Container(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter a username' : null,
                  onSaved: (value) => _username = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter an email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter a password' : null,
                  onSaved: (value) => _password = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _addNewAdmin(_username, _email, _password);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add Admin',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}