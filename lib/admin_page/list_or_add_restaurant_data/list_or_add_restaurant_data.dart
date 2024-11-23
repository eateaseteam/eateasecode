import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ListOrAddRestaurantData extends StatefulWidget {
  @override
  _ListOrAddRestaurantDataState createState() => _ListOrAddRestaurantDataState();
}

class _ListOrAddRestaurantDataState extends State<ListOrAddRestaurantData> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _restaurants = [
    {
      'id': 1,
      'name': 'The Sushi Bar',
      'owner': 'John Smith',
      'address': '123 Main St, Anytown USA',
      'email': 'sushi@example.com',
      'phoneNumber': '555-1234',
      'logo': 'logo1.png',
    },
    {
      'id': 2,
      'name': 'Pizzeria Delizioso',
      'owner': 'Maria Garcia',
      'address': '456 Elm St, Anytown USA',
      'email': 'pizza@example.com',
      'phoneNumber': '555-5678',
      'logo': 'logo2.png',
    },
    {
      'id': 3,
      'name': 'The Steakhouse',
      'owner': 'Robert Johnson',
      'address': '789 Oak Rd, Anytown USA',
      'email': 'steak@example.com',
      'phoneNumber': '555-9012',
      'logo': 'logo3.png',
    },
  ];

  List<Map<String, dynamic>> get _filteredRestaurants {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _restaurants;

    return _restaurants.where((restaurant) {
      return restaurant['name'].toLowerCase().contains(query) ||
          restaurant['owner'].toLowerCase().contains(query) ||
          restaurant['email'].toLowerCase().contains(query) ||
          restaurant['phoneNumber'].toLowerCase().contains(query);
    }).toList();
  }

  void _addNewRestaurant(Map<String, dynamic> restaurant) {
    setState(() {
      _restaurants.add({
        'id': _restaurants.length + 1,
        ...restaurant,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            Expanded(
              child: _buildRestaurantTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Text(
                'Restaurants Data',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _showAddRestaurantDialog(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[600],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Add Restaurant',
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
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Restaurants Data',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddRestaurantDialog(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[600],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Add Restaurant',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(height: 16),
              TextField(
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
            ],
          );
        }
      },
    );
  }

  Widget _buildRestaurantTable() {
    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
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
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Owner')),
              DataColumn(label: Text('Address')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Phone Number')),
              DataColumn(label: Text('Logo')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _filteredRestaurants.map((restaurant) {
              return DataRow(
                cells: [
                  DataCell(Text(restaurant['id'].toString())),
                  DataCell(Text(restaurant['name'])),
                  DataCell(Text(restaurant['owner'])),
                  DataCell(Text(restaurant['address'])),
                  DataCell(Text(restaurant['email'])),
                  DataCell(Text(restaurant['phoneNumber'])),
                  DataCell(
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.image, color: Colors.grey[400]),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 18),
                          onPressed: () {
                            // Edit logic
                          },
                          color: Colors.blue[600],
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 18),
                          onPressed: () {
                            // Delete logic
                          },
                          color: Colors.red[600],
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
  }

  void _showAddRestaurantDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _name = '';
    String _owner = '';
    String _address = '';
    String _email = '';
    String _phoneNumber = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Restaurant',
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
                    labelText: 'Restaurant Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter restaurant name' : null,
                  onSaved: (value) => _name = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Owner Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter owner name' : null,
                  onSaved: (value) => _owner = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter address' : null,
                  onSaved: (value) => _address = value!,
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
                    if (value!.isEmpty) return 'Please enter email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter phone number' : null,
                  onSaved: (value) => _phoneNumber = value!,
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
                _addNewRestaurant({
                  'name': _name,
                  'owner': _owner,
                  'address': _address,
                  'email': _email,
                  'phoneNumber': _phoneNumber,
                  'logo': 'default.png',
                });
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
              'Add Restaurant',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}