import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'about_us.dart';
import 'faqs.dart';
import 'privacy_and_policy.dart';

class ProfileScreen extends StatefulWidget {
  final String email;

  const ProfileScreen({required this.email, Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? profileImageUrl;
  final ImagePicker picker = ImagePicker();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to log out?',
                  style: GoogleFonts.poppins(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await FirebaseAuth.instance.signOut();
                          SystemNavigator.pop();
                        } catch (e) {
                          print('Logout failed: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProfileImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String fileName = 'profile_images/${FirebaseAuth.instance.currentUser!.uid}.jpg';
      File imageFile = File(pickedFile.path);
      try {
        await FirebaseStorage.instance.ref(fileName).putFile(imageFile);
        String downloadUrl = await FirebaseStorage.instance.ref(fileName).getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(widget.email).update({
          'profileImageUrl': downloadUrl,
        });

        setState(() {
          profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile picture updated successfully.')));
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile picture.')));
      }
    }
  }

  void _showProfileDialog(BuildContext context, String? profileImageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 100,
                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : AssetImage('lib/assets/app_images/official_logo.png') as ImageProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.email).update({
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.black),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _firstNameController.clear();
                  _lastNameController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.email).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("No user data found."));
          }

          final userDoc = snapshot.data!;
          final userData = userDoc.data() as Map<String, dynamic>?;
          final fullName = userData?['fullName'] ?? 'No Name';
          final userEmail = userData?['email'] ?? 'No Email';
          profileImageUrl = userData?['profileImageUrl'] as String?;

          if (!_isEditing) {
            _firstNameController.text = userData?['firstName'] ?? '';
            _lastNameController.text = userData?['lastName'] ?? '';
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(fullName: fullName, email: userEmail),
                SizedBox(height: 24),
                if (_isEditing) ...[
                  _buildEditProfileForm(),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ] else ...[
                  _buildProfileItem(
                    icon: Icons.payment,
                    title: 'Payment',
                    onTap: () {
                      _showGcashDialog(context); // Show GCash dialog
                    },
                  ),
                  SizedBox(height: 16),
                  _buildProfileItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy & Policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildProfileItem(
                    icon: Icons.help_outline,
                    title: 'FAQs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FAQScreen()),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildProfileItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutUsScreen()),
                      );
                    },
                  ),
                ],
                if (!_isEditing) ...[
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showGcashDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GCash Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Image.asset(
                  'lib/assets/app_images/gcash-logo.png', // Ensure this path is correct
                  height: 100,
                ),
                SizedBox(height: 16),
                Text(
                  'Use GCash for your payments.',
                  style: GoogleFonts.poppins(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'With GCash, you can easily pay for your purchases and services online. It offers a fast and secure way to manage your transactions without the need for cash.',
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), // Close dialog
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader({required String fullName, required String email}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () => _showProfileDialog(context, profileImageUrl),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? NetworkImage(profileImageUrl!)
                      : AssetImage('lib/assets/app_images/official_logo.png') as ImageProvider,
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _updateProfileImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: 24,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileForm() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepOrange),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: GoogleFonts.poppins(),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepOrange),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: GoogleFonts.poppins(),
          ),
        ],
      ),
    );
  }
}