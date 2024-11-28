import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class RestaurantManagement extends StatefulWidget {
  @override
  _RestaurantManagementState createState() => _RestaurantManagementState();
}

class _RestaurantManagementState extends State<RestaurantManagement> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _truncateWithEllipsis(String text, int maxLength) {
    return (text.length <= maxLength) ? text : '${text.substring(0, maxLength)}...';
  }

  Future<String?> uploadImageToFirebase(XFile image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('logos/$fileName');

      final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': image.path}
      );

      Uint8List imageData = await image.readAsBytes();
      UploadTask uploadTask = ref.putData(imageData, metadata);

      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _addNewRestaurant(
      String name,
      String owner,
      String address,
      String email,
      String password,
      String phoneNumber,
      String logoUrl,
      String about,
      ) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add restaurant to Firestore with the userId as document ID
      await FirebaseFirestore.instance.collection('restaurants').doc(userCredential.user!.uid).set({
        'name': name,
        'owner': owner,
        'address': address,
        'email': email,
        'phoneNumber': phoneNumber,
        'logoUrl': logoUrl,
        'about': about,
        'createdAt': Timestamp.now(),
        'uid': userCredential.user!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant added successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add restaurant: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editRestaurant(
      String uid,
      String name,
      String owner,
      String address,
      String email,
      String phoneNumber,
      String logoUrl,
      String about,
      ) async {
    try {
      // Update the restaurant document using the UID
      await FirebaseFirestore.instance.collection('restaurants').doc(uid).update({
        'name': name,
        'owner': owner,
        'address': address,
        'email': email,
        'phoneNumber': phoneNumber,
        'logoUrl': logoUrl,
        'about': about,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update restaurant: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteRestaurant(String uid) async {
    try {
      // Get the restaurant document using the UID
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance.collection('restaurants').doc(uid).get();

      if (restaurantDoc.exists) {
        // Delete the user from Firebase Auth
        await _auth.currentUser!.delete();

        // Delete the restaurant document from Firestore
        await FirebaseFirestore.instance.collection('restaurants').doc(uid).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restaurant deleted successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restaurant not found!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete restaurant: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
        padding: EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 30),
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
        SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: () => _showAddRestaurantDialog(context),
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add New Restaurant',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[600],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Spacer(),
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
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No restaurants yet.'));
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
        columns: [
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
        columns: [
          DataColumn(label: Text('Logo')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('About')),
          DataColumn(label: Text('Actions')),
        ],
        rows: restaurants.map((doc) => DataRow(
          cells: [
            DataCell(_buildLogoCell(doc.id)),
            DataCell(Text(doc['name'], overflow: TextOverflow.ellipsis)),
            DataCell(Text(doc['email'], overflow: TextOverflow.ellipsis)),
            DataCell(Text(doc['phoneNumber'] ?? 'N/A', overflow: TextOverflow.ellipsis)), // Phone number
            DataCell(Text(doc['address'] ?? 'N/A', overflow: TextOverflow.ellipsis)), // Address
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
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: _buildLogoCell(doc.id),
            title: Text(doc['name'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['email']),
                Text(doc['phoneNumber'] ?? 'N/A'), // Phone number
                Text(doc['address'] ?? 'N/A'), // Address
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
      future: FirebaseFirestore.instance.collection('restaurants').doc(docId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Icon(Icons.error, size: 40, color: Colors.red);
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
              return Icon(Icons.error, size: 40, color: Colors.red);
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
              : Icon(Icons.restaurant, size: 40);
        } else {
          return Icon(Icons.restaurant, size: 40);
        }
      },
    );
  }

  Widget _buildActionButtons(DocumentSnapshot doc) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.indigo[600]),
          onPressed: () => _showEditRestaurantDialog(context, doc),
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

  void _showAddRestaurantDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _name = '';
    String _owner = '';
    String _address = '';
    String _email = '';
    String _password = '';
    bool _obscureText = true;
    String _phoneNumber = '';
    String _logoUrl = '';
    String _about = '';
    bool _isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Add New Restaurant',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            content: Container(
              width: 400,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField('Restaurant Name', Icons.restaurant, (value) => _name = value),
                      SizedBox(height: 20),
                      _buildTextField('Owner Name', Icons.person, (value) => _owner = value),
                      SizedBox(height: 20),
                      _buildTextField('Address', Icons.location_on, (value) => _address = value),
                      SizedBox(height: 20),
                      _buildTextField('Email', Icons.email, (value) => _email = value, isEmail: true),
                      SizedBox(height: 20),
                      _buildTextField('Password', Icons.lock, (value) => _password = value, isPassword: true, obscureText: _obscureText, onToggleObscure: () => setState(() => _obscureText = !_obscureText)),
                      SizedBox(height: 20),
                      _buildTextField('Phone Number', Icons.phone, (value) => _phoneNumber = value),
                      SizedBox(height: 20),
                      _buildTextField('About', Icons.info_outline, (value) => _about = value, isMultiline: true),
                      SizedBox(height: 20),
                      _buildLogoPickerButton(_isUploading, () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() => _isUploading = true);
                          final url = await uploadImageToFirebase(image);
                          setState(() {
                            _logoUrl =
                                url ?? '';
                            _isUploading = false;
                          });
                          if (_logoUrl.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logo picked successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                onPressed: _isUploading ? null : () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _addNewRestaurant(_name, _owner, _address, _email, _password, _phoneNumber, _logoUrl, _about);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Add Restaurant', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRestaurantDialog(BuildContext context, DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    String _name = doc['name'];
    String _owner = doc['owner'];
    String _address = doc['address'];
    String _email = doc['email'];
    String _phoneNumber = doc['phoneNumber'];
    String _logoUrl = doc['logoUrl'];
    String _about = doc['about'] ?? '';
    bool _isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Edit Restaurant',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            content: Container(
              width: 400,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField('Restaurant Name', Icons.restaurant, (value) => _name = value, initialValue: _name),
                      SizedBox(height: 20),
                      _buildTextField('Owner Name', Icons.person, (value) => _owner = value, initialValue: _owner),
                      SizedBox(height: 20),
                      _buildTextField('Address', Icons.location_on, (value) => _address = value, initialValue: _address),
                      SizedBox(height: 20),
                      _buildTextField(
                        'Email',
                        Icons.email,
                            (value) => _email = value,
                        isEmail: true,
                        initialValue: _email,
                        enabled: false,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 20),
                      _buildTextField('Phone Number', Icons.phone, (value) => _phoneNumber = value, initialValue: _phoneNumber),
                      SizedBox(height: 20),
                      _buildTextField('About', Icons.info_outline, (value) => _about = value, initialValue: _about, isMultiline: true),
                      SizedBox(height: 20),
                      _buildLogoPickerButton(_isUploading, () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() => _isUploading = true);
                          final url = await uploadImageToFirebase(image);
                          setState(() {
                            _logoUrl = url ?? '';
                            _isUploading = false;
                          });
                          if (_logoUrl.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logo updated successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                onPressed: _isUploading ? null : () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _editRestaurant(doc.id, _name, _owner, _address, _email, _phoneNumber, _logoUrl, _about);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Update Restaurant', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
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

  Widget _buildTextField(
      String label,
      IconData icon,
      Function(String) onSaved, {
        bool isEmail = false,
        bool isPassword = false,
        bool obscureText = false,
        Function()? onToggleObscure,
        String? initialValue,
        bool enabled = true,
        TextStyle? style,
        bool isMultiline = false,
      }) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      style: style,
      maxLines: isMultiline ? null : 1,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon, color: Colors.indigo[600]),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.indigo[600],
          ),
          onPressed: onToggleObscure,
        )
            : null,
        hintText: label,
        hintStyle: style ?? TextStyle(color: Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      obscureText: isPassword && obscureText,
      validator: (value) {
        if (value!.isEmpty) return 'Please enter $label';
        if (isEmail && !value.contains('@')) return 'Please enter a valid email';
        return null;
      },
      onSaved: (value) => onSaved(value!),
    );
  }

  Widget _buildLogoPickerButton(bool isUploading, Function() onPressed) {
    return ElevatedButton.icon(
      onPressed: isUploading ? null : onPressed,
      icon: Icon(Icons.image),
      label: Text(isUploading ? 'Uploading...' : 'Pick Logo'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

