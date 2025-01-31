import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditMenuItemPage extends StatefulWidget {
  final String userId;
  final String? docId;
  final Map<String, dynamic>? item;

  const AddEditMenuItemPage({
    super.key,
    required this.userId,
    this.docId,
    this.item,
  });

  @override
  _AddEditMenuItemPageState createState() => _AddEditMenuItemPageState();
}

class _AddEditMenuItemPageState extends State<AddEditMenuItemPage> {
  final _menuItemController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Pork';
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _menuItemController.text = widget.item!['name'];
      _priceController.text = widget.item!['price'].toString();
      _descriptionController.text = widget.item!['description'];
      _selectedType = widget.item!['type'];
    }
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
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}', Colors.red);
    }
  }

  Future<String> _uploadImage(XFile image, Uint8List imageData) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference ref = _storage.ref().child('menu_images/$fileName');

    final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': image.path});

    final UploadTask uploadTask = ref.putData(imageData, metadata);
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _saveMenuItem() async {
    final menuItem = _menuItemController.text;
    final price = _priceController.text;
    final description = _descriptionController.text;

    if (menuItem.isNotEmpty && price.isNotEmpty) {
      setState(() => _isUploading = true);

      try {
        String? imageUrl;
        if (_selectedImage != null && _imageBytes != null) {
          imageUrl = await _uploadImage(_selectedImage!, _imageBytes!);
        }

        final Map<String, dynamic> itemData = {
          'name': menuItem,
          'price': double.parse(price),
          'description': description,
          'type': _selectedType,
          if (imageUrl != null) 'image': imageUrl,
          if (widget.docId == null) 'createdAt': FieldValue.serverTimestamp(),
        };

        if (widget.docId != null) {
          // Editing existing item
          final DocumentSnapshot oldData = await _firestore
              .collection('restaurants')
              .doc(widget.userId)
              .collection('menuItems')
              .doc(widget.docId)
              .get();

          await _firestore
              .collection('restaurants')
              .doc(widget.userId)
              .collection('menuItems')
              .doc(widget.docId)
              .update(itemData);

          // Log the edit action
          await _logActivity('Edit Menu Item', {
            'itemId': widget.docId,
            'oldData': oldData.data(),
            'newData': itemData,
          });
        } else {
          // Adding new item
          final docRef = await _firestore
              .collection('restaurants')
              .doc(widget.userId)
              .collection('menuItems')
              .add(itemData);

          // Log the add action
          await _logActivity('Add Menu Item', {
            'itemId': docRef.id,
            'itemData': itemData,
          });
        }

        _showSnackBar('Menu item saved successfully', Colors.green);
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Failed to save menu item: ${e.toString()}', Colors.red);
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      _showSnackBar('Please fill all required fields', Colors.orange);
    }
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
        'performedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  void _showFullScreenImage() {
    if (_imageBytes == null && widget.item == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      widget.item!['image'],
                      fit: BoxFit.contain,
                    ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Add Menu Item' : 'Edit Menu Item'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _showFullScreenImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : widget.item != null && widget.item!['image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.item!['image'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo, color: Colors.white),
                // Ensure the icon color is white
                label: const Text(
                  'Select Image',
                  style:
                      TextStyle(color: Colors.white), // Set text color to white
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _menuItemController,
                decoration: InputDecoration(
                  labelText: 'Menu Item Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items: ['Pork', 'Chicken', 'Seafood', 'Desserts', 'Beverages']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _saveMenuItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.docId == null
                            ? 'Add Menu Item'
                            : 'Update Menu Item',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white, // Set text color to white
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _menuItemController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
