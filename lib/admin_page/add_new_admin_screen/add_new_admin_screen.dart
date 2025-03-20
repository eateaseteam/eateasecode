import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _adminsStream;

  @override
  void initState() {
    super.initState();
    _adminsStream = FirebaseFirestore.instance
        .collection('admins')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _logActivity(String action, String details) async {
    try {
      String currentUserId =
          FirebaseAuth.instance.currentUser?.uid ?? 'Unknown';
      await FirebaseFirestore.instance.collection('admin_logs').add({
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'performedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
        'adminId': currentUserId,
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<void> _addNewAdmin(
      String username, String email, String password) async {
    try {
      // Create a new instance of FirebaseAuth
      FirebaseAuth tempAuth = FirebaseAuth.instance;

      // Create the new admin user
      UserCredential userCredential =
          await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Log the activity using the current user's ID, not the new admin's
        String currentUserId =
            FirebaseAuth.instance.currentUser?.uid ?? 'Unknown';
        await _logActivity('Add Admin', 'Added new admin: $username ($email)');

        _showSnackBar('Admin added successfully!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to add admin: $e', Colors.red);
    }
  }

  Future<void> _editAdmin(String docId, String username, String email) async {
    try {
      await FirebaseFirestore.instance.collection('admins').doc(docId).update({
        'username': username,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity('Edit Admin', 'Updated admin: $username ($email)');
      _showSnackBar('Admin updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to update admin: $e', Colors.red);
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await _logActivity(
          'Password Reset', 'Sent password reset email to: $email');
      _showSnackBar('Password reset email sent!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to send reset email: $e', Colors.red);
    }
  }

  Future<void> _deleteAdmin(String docId, String email) async {
    try {
      await FirebaseFirestore.instance.collection('admins').doc(docId).delete();
      await _logActivity('Delete Admin', 'Deleted admin: $email');
      _showSnackBar('Admin deleted successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to delete admin: $e', Colors.red);
    }
  }

  void _showAddAdminDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String username = '';
    String email = '';
    String password = '';
    bool isDialogPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add New Admin', style: _dialogTitleStyle),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      label: 'Username',
                      onSaved: (value) => username = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a username' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Email',
                      onSaved: (value) => email = value!,
                      validator: (value) => value!.isEmpty ||
                              !RegExp(r'\S+@\S+\.\S+').hasMatch(value)
                          ? 'Please enter a valid email address'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      label: 'Password',
                      isVisible: isDialogPasswordVisible,
                      onSaved: (value) => password = value!,
                      onVisibilityToggle: () => setState(() =>
                          isDialogPasswordVisible = !isDialogPasswordVisible),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          _addNewAdmin(username, email, password);
                          Navigator.pop(context);
                        }
                      },
                      style: _buttonStyle,
                      child: Text('Add Admin', style: _buttonTextStyle),
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
    final formKey = GlobalKey<FormState>();
    String username = doc['username'];
    String email = doc['email'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Admin', style: _dialogTitleStyle),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    label: 'Username',
                    initialValue: username,
                    onSaved: (value) => username = value!,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a username' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: email,
                    decoration: _inputDecoration('Email', Icons.email),
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        _editAdmin(doc.id, username, email);
                        Navigator.pop(context);
                      }
                    },
                    style: _buttonStyle,
                    child: Text('Save Changes', style: _buttonTextStyle),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String docId, String email) {
    String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    if (currentUserEmail == email) {
      _showSnackBar('You cannot delete your own account!', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Delete Admin?', style: _dialogTitleStyle),
          content: Text('Are you sure you want to delete this admin?',
              style: _dialogContentStyle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: _cancelButtonStyle),
            ),
            TextButton(
              onPressed: () {
                _deleteAdmin(docId, email);
                Navigator.pop(context);
              },
              child: Text('Delete', style: _deleteButtonStyle),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      prefixIcon: Icon(icon, color: Colors.indigo[600]),
    );
  }

  TextStyle get _dialogTitleStyle => GoogleFonts.poppins(
      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo[900]);

  TextStyle get _dialogContentStyle =>
      GoogleFonts.poppins(fontSize: 16, color: Colors.indigo[800]);

  TextStyle get _cancelButtonStyle => GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo[600]);

  TextStyle get _deleteButtonStyle => GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red[600]);

  ButtonStyle get _buttonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo[600],
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  TextStyle get _buttonTextStyle =>
      GoogleFonts.poppins(fontSize: 18, color: Colors.white);

  Widget _buildTextField({
    required String label,
    String? initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: _inputDecoration(label, Icons.person),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool isVisible,
    required FormFieldSetter<String> onSaved,
    required VoidCallback onVisibilityToggle,
  }) {
    return TextFormField(
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.lock, color: Colors.indigo[600]),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.indigo[600]),
          onPressed: onVisibilityToggle,
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
      onSaved: onSaved,
    );
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
                Row(
                  children: [
                    Text('Admin Data',
                        style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900])),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAdminDialog(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text('Add New Admin',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      style: _buttonStyle,
                    ),
                    const Spacer(),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration:
                            _inputDecoration('Search admins...', Icons.search),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _adminsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No admins yet.'));
                      }
                      final admins = snapshot.data!.docs;
                      final filteredAdmins = admins.where((doc) {
                        final query = _searchController.text.toLowerCase();
                        final username =
                            doc['username'].toString().toLowerCase();
                        final email = doc['email'].toString().toLowerCase();
                        return query.isEmpty ||
                            username.contains(query) ||
                            email.contains(query);
                      }).toList();

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(Colors.indigo[100]),
                          headingTextStyle: GoogleFonts.poppins(
                              color: Colors.indigo[900],
                              fontWeight: FontWeight.w600),
                          dataTextStyle:
                              GoogleFonts.poppins(color: Colors.indigo[800]),
                          columns: const [
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Created At')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredAdmins.map((doc) {
                            final createdAt = doc['createdAt'] as Timestamp?;
                            final formattedDate = createdAt != null
                                ? DateFormat('yyyy-MM-dd HH:mm')
                                    .format(createdAt.toDate())
                                : 'N/A';
                            return DataRow(
                              cells: [
                                DataCell(Text(doc['username'])),
                                DataCell(Text(doc['email'])),
                                DataCell(Text(formattedDate)),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.indigo[600]),
                                        onPressed: () =>
                                            _showEditAdminDialog(context, doc),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red[600]),
                                        onPressed: () =>
                                            _showDeleteConfirmationDialog(
                                                context, doc.id, doc['email']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.lock_reset,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _sendPasswordResetEmail(
                                                doc['email']),
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
}
