import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class MenuPage extends StatefulWidget {
  final String userId;

  MenuPage({required this.userId});

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> types = ['All', 'Pork', 'Chicken', 'Seafood', 'Desserts', 'Beverages'];
  final _menuItemController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Pork';
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: types.length, vsync: this);
  }

  Future<bool> _verifyAdminPassword(String password) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying admin password: $e');
      return false;
    }
  }

  void _showAddMenuItemDialog() {
    final passwordController = TextEditingController();
    bool _obscurePassword = true; // State variable for password visibility

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Verify Admin', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword; // Toggle password visibility
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await _verifyAdminPassword(passwordController.text)) {
                Navigator.pop(context);
                _showAddMenuItemFormDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid admin password'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Verify'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }


  void _showAddMenuItemFormDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Menu Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _menuItemController,
                decoration: InputDecoration(labelText: 'Menu Item'),
              ),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'Type'),
                items: types.where((e) => e != 'All').map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select Image'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              if (_imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.memory(
                    _imageBytes!,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Text('Error loading image');
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _addMenuItem,
            child: _isUploading ? CircularProgressIndicator(color: Colors.white) : Text('Add'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  Future<void> _addMenuItem() async {
    final menuItem = _menuItemController.text;
    final price = _priceController.text;
    final description = _descriptionController.text;

    if (menuItem.isNotEmpty && price.isNotEmpty && _selectedImage != null && _imageBytes != null) {
      setState(() => _isUploading = true);

      try {
        final imageUrl = await _uploadImage(_selectedImage!, _imageBytes!);
        await _saveMenuItemToFirestore(menuItem, price, description, imageUrl);
        _resetForm();
        _showSnackBar('Menu item added successfully', Colors.green);
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Failed to add menu item: ${e.toString()}', Colors.red);
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      _showSnackBar('Please fill all fields and select an image', Colors.orange);
    }
  }

  Future<String> _uploadImage(XFile image, Uint8List imageData) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference ref = FirebaseStorage.instance.ref().child('menu_images/$fileName');

    final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': image.path}
    );

    final UploadTask uploadTask = ref.putData(imageData, metadata);
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _saveMenuItemToFirestore(String name, String price, String description, String imageUrl) async {
    final restaurantRef = FirebaseFirestore.instance.collection('restaurants').doc(widget.userId);
    final menuItemsRef = restaurantRef.collection('menuItems');
    await menuItemsRef.add({
      'name': name,
      'price': double.parse(price),
      'description': description,
      'type': _selectedType,
      'image': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _editMenuItem(String docId, Map<String, dynamic> newData) async {
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.userId)
          .collection('menuItems')
          .doc(docId)
          .update(newData);
      _showSnackBar('Menu item updated successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to update menu item: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _deleteMenuItem(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.userId)
          .collection('menuItems')
          .doc(docId)
          .delete();
      _showSnackBar('Menu item deleted successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to delete menu item: ${e.toString()}', Colors.red);
    }
  }

  void _resetForm() {
    _menuItemController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = 'Pork';
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final Uint8List imageData = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = imageData;
        });
        _showSnackBar('Image selected successfully', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}', Colors.red);
    }
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
        onPressed: _showAddMenuItemDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
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
          SizedBox(height: 16),
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
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.userId)
          .collection('menuItems')
          .where('type', isEqualTo: type == 'All' ? null : type)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No items in this type'));
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.error, color: Colors.red, size: 30),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                        'PHP ${item['price']}',
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
                        icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _showEditMenuItemDialog(docId, item),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _showDeleteConfirmationDialog(docId),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
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

  void _showEditMenuItemDialog(String docId, Map<String, dynamic> item) {
    _menuItemController.text = item['name'];
    _priceController.text = item['price'].toString();
    _descriptionController.text = item['description'];
    _selectedType = item['type'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Menu Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _menuItemController,
                decoration: InputDecoration(labelText: 'Menu Item'),
              ),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'Type'),
                items: types.where((e) => e != 'All').map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await _verifyAdminPassword(await _showPasswordDialog())) {
                _editMenuItem(docId, {
                  'name': _menuItemController.text,
                  'price': double.parse(_priceController.text),
                  'description': _descriptionController.text,
                  'type': _selectedType,
                });
                Navigator.pop(context);
              } else {
                _showSnackBar('Invalid admin password', Colors.red);
              }
            },
            child: Text('Update'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Menu Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this menu item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await _verifyAdminPassword(await _showPasswordDialog())) {
                _deleteMenuItem(docId);
                Navigator.pop(context);
              } else {
                _showSnackBar('Invalid admin password', Colors.red);
              }
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<String> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool _obscurePassword = true; // State variable for password visibility

    // Use the await to capture the result from the dialog
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Admin Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword; // Toggle password visibility
                    });
                  },
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''), // Return empty string if canceled
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, passwordController.text); // Return the password when verified
            },
            child: Text('Verify'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );

    // Ensure a non-null value is returned by providing a default if result is null
    return result ?? '';  // Return empty string if result is null
  }


  @override
  void dispose() {
    _menuItemController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

