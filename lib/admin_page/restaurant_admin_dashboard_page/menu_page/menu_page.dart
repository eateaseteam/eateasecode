import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_edit_menu_item_page.dart';

class MenuPage extends StatefulWidget {
  final String userId;

  const MenuPage({super.key, required this.userId});

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> types = [
    'All',
    'Pork',
    'Chicken',
    'Seafood',
    'Desserts',
    'Beverages'
  ];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: types.length, vsync: this);
  }

  Future<void> _logActivity(String action, Map<String, dynamic> details) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(widget.userId)
          .collection('menu_logs')
          .add({
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'performedBy': _auth.currentUser?.email ?? 'Unknown',
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<bool> _verifyAdminPassword(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying admin password: $e');
      return false;
    }
  }

  void _navigateToAddEditMenuItemPage(
      {String? docId, Map<String, dynamic>? item}) {
    _showPasswordDialog().then((password) {
      if (password.isNotEmpty) {
        _verifyAdminPassword(password).then((isVerified) {
          if (isVerified) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditMenuItemPage(
                  userId: widget.userId,
                  docId: docId,
                  item: item,
                ),
              ),
            ).then((_) => setState(() {})); // Refresh the page when returning
          } else {
            _showSnackBar('Invalid admin password', Colors.red);
          }
        });
      }
    });
  }

  Future<void> _deleteMenuItem(String docId, String itemName) async {
    try {
      final DocumentSnapshot deletedItem = await _firestore
          .collection('restaurants')
          .doc(widget.userId)
          .collection('menuItems')
          .doc(docId)
          .get();

      await _firestore
          .collection('restaurants')
          .doc(widget.userId)
          .collection('menuItems')
          .doc(docId)
          .delete();

      await _logActivity('Delete Menu Item', {
        'itemId': docId,
        'name': itemName,
        'deletedData': deletedItem.data(),
      });

      _showSnackBar('Menu item deleted successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to delete menu item: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: types.map((type) => _buildTypeView(type)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditMenuItemPage(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: types.map((type) => Tab(text: type)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeView(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('restaurants')
          .doc(widget.userId)
          .collection('menuItems')
          .where('type', isEqualTo: type == 'All' ? null : type)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No items in this type'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final item = doc.data() as Map<String, dynamic>;
            return _buildMenuItemCard(doc.id, item);
          },
        );
      },
    );
  }

  Widget _buildMenuItemCard(String docId, Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red, size: 30),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(7.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'PHP ${item['price'].toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item['description'],
                        style: GoogleFonts.poppins(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue, size: 20),
                        onPressed: () => _navigateToAddEditMenuItemPage(
                            docId: docId, item: item),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 20),
                        onPressed: () =>
                            _showDeleteConfirmationDialog(docId, item['name']),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String docId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Menu Item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this menu item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = await _showPasswordDialog();
              if (await _verifyAdminPassword(password)) {
                _deleteMenuItem(docId, itemName);
                Navigator.pop(context);
              } else {
                _showSnackBar('Invalid admin password', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white, // Sets the text color to white
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<String> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Enter Admin Password',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: StatefulBuilder(
              builder: (context, setState) {
                return TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, passwordController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white, // Sets the text color to white
                ),
                child: const Text('Verify'),
              ),
            ],
          ),
        ) ??
        '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
