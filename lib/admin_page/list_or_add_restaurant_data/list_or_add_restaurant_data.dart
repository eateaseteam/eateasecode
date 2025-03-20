import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add-edit-restaurant-page.dart';

class RestaurantManagement extends StatefulWidget {
  const RestaurantManagement({super.key});

  @override
  _RestaurantManagementState createState() => _RestaurantManagementState();
}

class _RestaurantManagementState extends State<RestaurantManagement> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _logActivity(String action, String details) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await FirebaseFirestore.instance.collection('admin_logs').add({
          'action': action,
          'details': details,
          'timestamp': FieldValue.serverTimestamp(),
          'performedBy': _auth.currentUser?.email ?? 'Unknown',
          'adminId': currentUserId,
        });
      }
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<void> _disableRestaurant(String uid) async {
    try {
      DocumentSnapshot restaurantDoc =
          await _firestore.collection('restaurants').doc(uid).get();

      if (restaurantDoc.exists) {
        String restaurantName = restaurantDoc['name'];
        String ownerName = restaurantDoc['owner'];

        // Update the 'disabled' field to true
        await _firestore
            .collection('restaurants')
            .doc(uid)
            .update({'disabled': true});

        await _logActivity('Disable Restaurant',
            'Disabled restaurant: $restaurantName (Owner: $ownerName)');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restaurant disabled successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restaurant not found!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to disable restaurant: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _logActivity(
          'Password Reset', 'Sent password reset email to: $email');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                Expanded(child: _buildRestaurantList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Restaurant Data',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddEditRestaurantPage()),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add New Restaurant',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[600],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search restaurants...',
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
      ],
    );
  }

  Widget _buildRestaurantList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('restaurants')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No restaurants yet.'));
        }
        final restaurants = snapshot.data!.docs;
        final filteredRestaurants = restaurants.where((doc) {
          final query = _searchController.text.toLowerCase();
          final name = doc['name'].toString().toLowerCase();
          final owner = doc['owner'].toString().toLowerCase();
          return query.isEmpty || name.contains(query) || owner.contains(query);
        }).toList();

        return _buildResponsiveDataTable(filteredRestaurants);
      },
    );
  }

  Widget _buildResponsiveDataTable(List<DocumentSnapshot> restaurants) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return _buildFullDataTable(restaurants);
        } else if (constraints.maxWidth > 800) {
          return _buildMediumDataTable(restaurants);
        } else {
          return _buildCompactDataTable(restaurants);
        }
      },
    );
  }

  Widget _buildFullDataTable(List<DocumentSnapshot> restaurants) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 12,
        headingRowColor: WidgetStateProperty.all(Colors.indigo[100]),
        headingTextStyle: GoogleFonts.poppins(
          color: Colors.indigo[900],
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: GoogleFonts.poppins(
          color: Colors.indigo[800],
        ),
        columns: const [
          DataColumn(label: Text('Logo')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Owner')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('About')),
          DataColumn(label: Text('Actions')),
        ],
        rows: restaurants.map((doc) => _buildRestaurantRow(doc)).toList(),
      ),
    );
  }

  Widget _buildMediumDataTable(List<DocumentSnapshot> restaurants) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 12,
        headingRowColor: WidgetStateProperty.all(Colors.indigo[100]),
        headingTextStyle: GoogleFonts.poppins(
          color: Colors.indigo[900],
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: GoogleFonts.poppins(
          color: Colors.indigo[800],
        ),
        columns: const [
          DataColumn(label: SizedBox(width: 60, child: Text('Logo'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Name'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Owner'))),
          DataColumn(label: SizedBox(width: 150, child: Text('Email'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Phone'))),
          DataColumn(label: SizedBox(width: 150, child: Text('Address'))),
          DataColumn(label: SizedBox(width: 150, child: Text('About'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Actions'))),
        ],
        rows: restaurants.map((doc) => _buildRestaurantRow(doc)).toList(),
      ),
    );
  }

  Widget _buildCompactDataTable(List<DocumentSnapshot> restaurants) {
    return ListView.builder(
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final doc = restaurants[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ExpansionTile(
            leading: _buildLogoCell(doc.id),
            title: Text(doc['name'],
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            subtitle: Text(doc['owner'],
                style: GoogleFonts.poppins(color: Colors.grey[600])),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.email, 'Email', doc['email']),
                    _buildInfoRow(
                        Icons.phone, 'Phone', doc['phoneNumber'] ?? 'N/A'),
                    _buildInfoRow(
                        Icons.location_on, 'Address', doc['address'] ?? 'N/A'),
                    _buildInfoRow(Icons.info_outline, 'About',
                        doc['about'] ?? 'No description',
                        maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButtons(doc),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.indigo[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[700])),
                Text(
                  value,
                  style: GoogleFonts.poppins(color: Colors.grey[800]),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRestaurantRow(DocumentSnapshot doc) {
    return DataRow(
      cells: [
        DataCell(_buildLogoCell(doc.id)),
        DataCell(_buildEllipsisText(doc['name'], 100)),
        DataCell(_buildEllipsisText(doc['owner'], 100)),
        DataCell(_buildEllipsisText(doc['email'], 150)),
        DataCell(_buildEllipsisText(doc['phoneNumber'], 100)),
        DataCell(_buildEllipsisText(doc['address'], 150)),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              doc['about'] ?? 'No description',
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ),
        DataCell(_buildActionButtons(doc)),
      ],
    );
  }

  Widget _buildLogoCell(String docId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('restaurants').doc(docId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return const Icon(Icons.error, size: 40, color: Colors.red);
        }
        if (snapshot.hasData) {
          String? logoUrl = snapshot.data!['logoUrl'];
          return logoUrl != null && logoUrl.isNotEmpty
              ? Image.network(
                  logoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return const Icon(Icons.error, size: 40, color: Colors.red);
                  },
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : const Icon(Icons.restaurant, size: 40);
        } else {
          return const Icon(Icons.restaurant, size: 40);
        }
      },
    );
  }

  // Function to enable the restaurant
  Future<void> _enableRestaurant(String uid) async {
    try {
      DocumentSnapshot restaurantDoc =
          await _firestore.collection('restaurants').doc(uid).get();

      if (restaurantDoc.exists) {
        String restaurantName = restaurantDoc['name'];
        String ownerName = restaurantDoc['owner'];

        // Update the 'disabled' field to false
        await _firestore
            .collection('restaurants')
            .doc(uid)
            .update({'disabled': false});

        await _logActivity('Enable Restaurant',
            'Enabled restaurant: $restaurantName (Owner: $ownerName)');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restaurant enabled successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restaurant not found!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to enable restaurant: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // Updated action buttons with Enable/Disable Logic
  Widget _buildActionButtons(DocumentSnapshot doc) {
    bool isDisabled =
        doc['disabled'] ?? false; // Read the 'disabled' status from Firestore

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.indigo[600]),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditRestaurantPage(
                restaurantId: doc.id,
                restaurantData: doc.data() as Map<String, dynamic>,
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            isDisabled ? Icons.toggle_on : Icons.toggle_off,
            color: isDisabled ? Colors.green : Colors.red,
          ),
          onPressed: () {
            if (isDisabled) {
              _showEnableConfirmationDialog(context, doc.id);
            } else {
              _showDisableConfirmationDialog(context, doc.id);
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.lock_reset, color: Colors.orange[600]),
          onPressed: () => _sendPasswordResetEmail(doc['email']),
        ),
      ],
    );
  }

  void _showEnableConfirmationDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Enable',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content:
              const Text('Are you sure you want to enable this restaurant?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _enableRestaurant(docId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(
                'Enable',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDisableConfirmationDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Disable',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content:
              const Text('Are you sure you want to disable this restaurant?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _disableRestaurant(docId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              child: Text(
                'Disable',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEllipsisText(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
