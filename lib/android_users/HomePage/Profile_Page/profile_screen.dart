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

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      SystemNavigator.pop();
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  Future<void> _updateProfileImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Upload the image to Firebase Storage
      String fileName = 'profile_images/${FirebaseAuth.instance.currentUser!.uid}.jpg';
      File imageFile = File(pickedFile.path);
      try {
        await FirebaseStorage.instance.ref(fileName).putFile(imageFile);
        String downloadUrl = await FirebaseStorage.instance.ref(fileName).getDownloadURL();

        // Update Firestore document with new image URL
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
      barrierColor: Colors.black.withOpacity(0.7), // Dimmed background
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full-screen blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Centered profile image
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
          profileImageUrl = userData != null &&
              userData.containsKey('profileImageUrl') &&
              userData['profileImageUrl'] != null
              ? userData['profileImageUrl'] as String
              : null;


          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(fullName: fullName, email: userEmail),
                SizedBox(height: 24),
                _buildProfileItem(
                  icon: Icons.payment,
                  title: 'Payment',
                  onTap: () {
                    // Navigate to payment settings
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
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
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
            ),
          );
        },
      ),
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
}
