import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add-edit-restaurant-page.dart';

class RestaurantManagement extends StatefulWidget {
  const RestaurantManagement({Key? key}) : super(key: key);

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
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(currentUserId)
            .collection('list_or_add_restaurant_activity_logs')
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

  Future<void> _deleteRestaurant(String uid) async {
    try {
      DocumentSnapshot restaurantDoc = await _firestore.collection('restaurants').doc(uid).get();

      if (restaurantDoc.exists) {
        String restaurantName = restaurantDoc['name'];
        String ownerName = restaurantDoc['owner'];

        await _firestore.collection('restaurants').doc(uid).delete();

        await _logActivity('Delete Restaurant', 'Deleted restaurant: $restaurantName (Owner: $ownerName)');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant deleted successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant not found!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete restaurant: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _logActivity('Password Reset', 'Sent password reset email to: $email');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            MaterialPageRoute(builder: (context) => AddEditRestaurantPage()),
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
        headingRowColor: MaterialStateProperty.all(Colors.indigo[100]),
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
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
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
        headingRowColor: MaterialStateProperty.all(Colors.indigo[100]),
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
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('Actions')),
        ],
        rows: restaurants.map((doc) => DataRow(
          cells: [
            DataCell(_buildLogoCell(doc.id)),
            DataCell(Text(doc['name'], overflow: TextOverflow.ellipsis)),
            DataCell(Text(doc['email'], overflow: TextOverflow.ellipsis)),
            DataCell(Text(doc['phoneNumber'] ?? 'N/A', overflow: TextOverflow.ellipsis)),
            DataCell(Text(doc['address'] ?? 'N/A', overflow: TextOverflow.ellipsis)),
            DataCell(_buildActionButtons(doc)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildCompactDataTable(List<DocumentSnapshot> restaurants) {
    return ListView.builder(
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final doc = restaurants[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: _buildLogoCell(doc.id),
            title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['email']),
                Text(doc['phoneNumber'] ?? 'N/A'),
                Text(doc['address'] ?? 'N/A'),
              ],
            ),
            trailing: _buildActionButtons(doc),
          ),
        );
      },
    );
  }

  DataRow _buildRestaurantRow(DocumentSnapshot doc) {
    return DataRow(
      cells: [
        DataCell(_buildLogoCell(doc.id)),
        DataCell(Text(doc['name'], overflow: TextOverflow.ellipsis)),
        DataCell(Text(doc['owner'], overflow: TextOverflow.ellipsis)),
        DataCell(Text(doc['address'], overflow: TextOverflow.ellipsis)),
        DataCell(Text(doc['email'], overflow: TextOverflow.ellipsis)),
        DataCell(Text(doc['phoneNumber'], overflow: TextOverflow.ellipsis)),
        DataCell(
          Container(
            width: 200,
            child: Text(
              doc['about'] ?? 'No description',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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

  Widget _buildActionButtons(DocumentSnapshot doc) {
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
          icon: Icon(Icons.delete, color: Colors.red[600]),
          onPressed: () => _showDeleteConfirmationDialog(context, doc.id),
        ),
        IconButton(
          icon: Icon(Icons.lock_reset, color: Colors.orange[600]),
          onPressed: () => _sendPasswordResetEmail(doc['email']),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Delete',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
          content: Text(
            'Are you sure you want to delete this restaurant?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.indigo[800],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _deleteRestaurant(docId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

