import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<bool> _showPasswordConfirmationDialog(BuildContext context) async {
    final _passwordController = TextEditingController();
    bool _isPasswordVisible = false;
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Confirm Your Password',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Please enter your password to continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.indigo[800],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.indigo[600]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.indigo[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Get current user
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // Reauthenticate user
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: _passwordController.text,
                        );
                        await user.reauthenticateWithCredential(credential);
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid password'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      Navigator.of(context).pop(false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }


  void _addNewAdmin(String username, String email, String password) async {
    final adminCollection = FirebaseFirestore.instance.collection('admins');
    final auth = FirebaseAuth.instance;

    try {
      // Create the new admin in Firebase Authentication
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the authenticated user
      User? user = userCredential.user;
      if (user != null) {
        // Optional: You can set additional fields like 'uid' in Firestore if needed
        await adminCollection.doc(user.uid).set({
          'uid': user.uid, // Store the Firebase Auth UID
          'username': username,
          'email': email,
          'createdAt': Timestamp.now(),
        }, SetOptions(merge: true));

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editAdmin(String docId, String username, String email) async {
    final adminCollection = FirebaseFirestore.instance.collection('admins');
    try {
      await adminCollection.doc(docId).update({
        'username': username,
        'email': email,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to send password reset email
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
                Row(
                  children: [
                    Text(
                      'Admin Data',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAdminDialog(context),
                      icon: Icon(Icons.add, color: Colors.white),  // Icon color set to white
                      label: Text(
                        'Add New Admin',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,  // Text color set to white
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],  // Button background color
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
                          hintText: 'Search admins...',
                          prefixIcon: Icon(Icons.search, color: Colors.indigo[400]),
                          filled: true,
                          fillColor: Colors.indigo[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Trigger a rebuild to filter results
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('admins')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No admins yet.'));
                      }
                      final admins = snapshot.data!.docs;
                      final filteredAdmins = admins.where((doc) {
                        final query = _searchController.text.toLowerCase();
                        final username = doc['username'].toLowerCase();
                        final email = doc['email'].toLowerCase();
                        return query.isEmpty ||
                            username.contains(query) ||
                            email.contains(query);
                      }).toList();

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.indigo[100],
                          ),
                          headingTextStyle: GoogleFonts.poppins(
                            color: Colors.indigo[900],
                            fontWeight: FontWeight.w600,
                          ),
                          dataTextStyle: GoogleFonts.poppins(
                            color: Colors.indigo[800],
                          ),
                          columns: [
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Actions')),  // Removed Password column
                          ],
                          rows: filteredAdmins.map((doc) {
                            return DataRow(
                              cells: [
                                DataCell(Text(doc['username'])),
                                DataCell(Text(doc['email'])),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.indigo[600]),
                                        onPressed: () {
                                          _showEditAdminDialog(context, doc);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red[600]),
                                        onPressed: () {
                                          _showDeleteConfirmationDialog(context, doc.id);
                                        },
                                      ),
                                      // Forgot Password Button
                                      IconButton(
                                        icon: Icon(Icons.lock_reset, color: Colors.blue),
                                        onPressed: () {
                                          _sendPasswordResetEmail(doc['email']);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteAdmin(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('admins').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddAdminDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _username = '';
    String _email = '';
    String _password = '';
    bool _isDialogPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Add New Admin',
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Username Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.person, color: Colors.indigo[600]),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a username' : null,
                      onSaved: (value) => _username = value!,
                    ),
                    SizedBox(height: 20),

                    // Editable Email Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.email, color: Colors.indigo[600]),
                      ),
                      validator: (value) => value!.isEmpty ||
                          !RegExp(r'\S+@\S+\.\S+').hasMatch(value)
                          ? 'Please enter a valid email address'
                          : null,
                      onSaved: (value) => _email = value!,
                    ),
                    SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      obscureText: !_isDialogPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.indigo[600]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isDialogPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.indigo[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _isDialogPasswordVisible = !_isDialogPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a password' : null,
                      onSaved: (value) => _password = value!,
                    ),
                    SizedBox(height: 20),

                    // Add Admin Button
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _addNewAdmin(_username, _email, _password);
                          Navigator.pop(context); // Close the dialog
                        }
                      },
                      child: Text(
                        'Add Admin',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white, // Set text color to white
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditAdminDialog(BuildContext context, DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    String _username = doc['username'];
    String _email = doc['email'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Admin',
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _username,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.indigo[600]),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter a username' : null,
                    onSaved: (value) => _username = value!,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    enabled: false, // Make the email field non-editable
                    initialValue: _email,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.grey.shade300, // Gray background for disabled field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.indigo[600]),
                    ),
                    validator: (value) =>
                    value!.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)
                        ? 'Please enter a valid email address'
                        : null,
                    onSaved: (value) => _email = value!,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _editAdmin(doc.id, _username, _email);
                        Navigator.pop(context); // Close the dialog
                      }
                    },
                    child: Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners for modern look
          ),
          title: Text(
            'Delete Admin?',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900], // Match with your color scheme
            ),
          ),
          content: Text(
            'Are you sure you want to delete this admin?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.indigo[800], // Slightly muted color for content
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo[600], // Use the same color as the button text
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteAdmin(docId); // Delete the admin
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600], // Use red for delete action
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}