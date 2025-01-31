import 'package:eatease_app_web/admin_page/login_screen/adminResto_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AddEditRestaurantPage extends StatefulWidget {
  final String? restaurantId;
  final Map<String, dynamic>? restaurantData;

  const AddEditRestaurantPage(
      {super.key, this.restaurantId, this.restaurantData});

  @override
  _AddEditRestaurantPageState createState() => _AddEditRestaurantPageState();
}

class _AddEditRestaurantPageState extends State<AddEditRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  String _logoUrl = '';
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  bool _obscurePassword = true;

  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.restaurantData != null) {
      _nameController.text = widget.restaurantData!['name'];
      _ownerController.text = widget.restaurantData!['owner'];
      _addressController.text = widget.restaurantData!['address'];
      _emailController.text = widget.restaurantData!['email'];
      _phoneNumberController.text = widget.restaurantData!['phoneNumber'];
      _aboutController.text = widget.restaurantData!['about'] ?? '';
      _logoUrl = widget.restaurantData!['logoUrl'] ?? '';
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
    final Reference ref = _storage.ref().child('logos/$fileName');

    final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': image.path});

    final UploadTask uploadTask = ref.putData(imageData, metadata);
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _saveRestaurant() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      try {
        // Store current admin's email before any authentication changes
        final currentAdminEmail = _auth.currentUser?.email;

        String? imageUrl;
        if (_selectedImage != null && _imageBytes != null) {
          imageUrl = await _uploadImage(_selectedImage!, _imageBytes!);
        }

        final Map<String, dynamic> restaurantData = {
          'name': _nameController.text,
          'owner': _ownerController.text,
          'address': _addressController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneNumberController.text,
          'about': _aboutController.text,
          'disabled': false, // Initialize the disabled field
          if (imageUrl != null) 'logoUrl': imageUrl,
          if (widget.restaurantId == null)
            'createdAt': FieldValue.serverTimestamp(),
        };

        if (widget.restaurantId != null) {
          // Editing existing restaurant
          final updatedFields = _getUpdatedFields(restaurantData);
          await _firestore
              .collection('restaurants')
              .doc(widget.restaurantId)
              .update(updatedFields);

          // Log activity with current admin's email
          await _logActivity(
              'Edit Restaurant', updatedFields, currentAdminEmail);

          _showSnackBar('Restaurant updated successfully', Colors.green);
          Navigator.pop(context);
        } else {
          // Adding new restaurant
          try {
            // Create a temporary auth instance for the new restaurant
            FirebaseAuth tempAuth = FirebaseAuth.instance;
            UserCredential userCredential =
                await tempAuth.createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

            restaurantData['uid'] = userCredential.user!.uid;

            // Add the restaurant data
            await _firestore
                .collection('restaurants')
                .doc(userCredential.user!.uid)
                .set(restaurantData);

            // Log activity with stored admin email
            await _logActivity(
                'Add Restaurant', restaurantData, currentAdminEmail);

            // Sign out the temporary user
            await tempAuth.signOut();

            _showSnackBar('Restaurant saved successfully', Colors.green);

            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AdminLoginPage()),
              (Route<dynamic> route) => false,
            );
          } catch (authError) {
            _showSnackBar(
                'Failed to create restaurant account: ${authError.toString()}',
                Colors.red);
          }
        }
      } catch (e) {
        _showSnackBar('Failed to save restaurant: ${e.toString()}', Colors.red);
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Map<String, dynamic> _getUpdatedFields(Map<String, dynamic> newData) {
    final Map<String, dynamic> updatedFields = {};
    newData.forEach((key, value) {
      if (widget.restaurantData == null ||
          widget.restaurantData![key] != value) {
        updatedFields[key] = value;
      }
    });
    return updatedFields;
  }

  Future<void> _logActivity(
      String action, Map<String, dynamic> details, String? adminEmail) async {
    try {
      await FirebaseFirestore.instance.collection('admin_logs').add({
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'performedBy': adminEmail ?? 'Unknown',
        'adminId': _auth.currentUser?.uid ?? 'Unknown',
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
    if (_imageBytes == null && _logoUrl.isEmpty) return;

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
                      _logoUrl,
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
        title: Text(
          widget.restaurantId == null ? 'Add Restaurant' : 'Edit Restaurant',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[600],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
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
                        : _logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _logoUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.restaurant,
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
                  label: const Text(
                    'Select Logo',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                    _nameController, 'Restaurant Name', Icons.restaurant),
                const SizedBox(height: 16),
                _buildTextField(_ownerController, 'Owner Name', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(
                    _addressController, 'Address', Icons.location_on),
                const SizedBox(height: 16),
                _buildTextField(_emailController, 'Email', Icons.email,
                    isEmail: true),
                const SizedBox(height: 16),
                if (widget.restaurantId == null)
                  _buildTextField(_passwordController, 'Password', Icons.lock,
                      isPassword: true),
                if (widget.restaurantId == null) const SizedBox(height: 16),
                _buildTextField(
                    _phoneNumberController, 'Phone Number', Icons.phone),
                const SizedBox(height: 16),
                _buildTextField(_aboutController, 'About', Icons.info_outline,
                    isMultiline: true),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isUploading ? null : _saveRestaurant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
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
                          widget.restaurantId == null
                              ? 'Add Restaurant'
                              : 'Update Restaurant',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isEmail = false,
    bool isPassword = false,
    bool isMultiline = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      maxLines: isMultiline ? null : 1,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo[600]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.indigo[600],
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isEmail && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
}
