import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Createteacher extends StatefulWidget {
  const Createteacher({super.key});

  @override
  State<Createteacher> createState() => _CreateteacherState();
}

class _CreateteacherState extends State<Createteacher> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _adminPasswordVisible = false;
  bool _showError = false;
  bool _showSuccess = false;
  String _errorMessage = "";
  bool _isLoading = false;

  String hodBranch = '';
  List<String> branchSubjects = [];
  List<String> selectedSubjects = [];

  // Color definitions
  Color primaryGreen = const Color(0xFF006400);
  Color lightGreen = const Color(0xFFE8F5E8);
  Color darkGreen = const Color(0xFF004D00);

  @override
  void initState() {
    super.initState();
    _fetchHodBranchAndSubjects();
  }

  /// Fetch the logged-in HOD's branch and its subjects
  Future<void> _fetchHodBranchAndSubjects() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get HOD/ADMIN user data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (!userDoc.exists) return;

    hodBranch = userDoc['branch'] ?? '';

    // Fetch subjects from branch collection
    if (hodBranch.isNotEmpty) {
      final branchDoc = await FirebaseFirestore.instance
          .collection('branch')
          .doc(hodBranch)
          .get();

      if (branchDoc.exists) {
        branchSubjects = List<String>.from(branchDoc['subjects'] ?? []);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Teacher Registration",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    color: primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Register New Teacher",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                    ),
                  ),
                  Text(
                    "Fill in the details below to create a teacher account",
                    style: TextStyle(
                      fontSize: 14,
                      color: darkGreen.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Input Fields
            _buildTextField(
              controller: _nameController,
              labelText: "Full Name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              labelText: "Email",
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _passwordController,
              labelText: "Teacher Password",
              isVisible: _passwordVisible,
              onToggleVisibility: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _adminPasswordController,
              labelText: "Admin Password",
              isVisible: _adminPasswordVisible,
              onToggleVisibility: () => setState(() => _adminPasswordVisible = !_adminPasswordVisible),
            ),
            const SizedBox(height: 24),

            // Subjects Section
            Text(
              "Select Subjects:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryGreen.withOpacity(0.2)),
              ),
              child: _buildSubjectsList(),
            ),
            const SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerTeacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: primaryGreen.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "Register Teacher",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Messages
            if (_showError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_showSuccess)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Teacher registered successfully!",
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: darkGreen.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: lightGreen.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: darkGreen.withOpacity(0.7)),
        prefixIcon: Icon(Icons.lock_outline, color: primaryGreen),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: primaryGreen,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: lightGreen.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    if (hodBranch.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Unable to fetch branch details",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    } else if (branchSubjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "No subjects found for this branch",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    } else {
      return Column(
        children: branchSubjects
            .map((subject) => Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: primaryGreen.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: CheckboxListTile(
            title: Text(
              subject,
              style: TextStyle(
                color: darkGreen,
                fontSize: 14,
              ),
            ),
            value: selectedSubjects.contains(subject),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedSubjects.add(subject);
                } else {
                  selectedSubjects.remove(subject);
                }
              });
            },
            activeColor: primaryGreen,
            checkColor: Colors.white,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ))
            .toList(),
      );
    }
  }

  /// Register teacher account
  Future<void> _registerTeacher() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _adminPasswordController.text.isEmpty ||
        selectedSubjects.isEmpty) {
      setState(() {
        _showError = true;
        _errorMessage = "All fields and subjects are required.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showError = false;
      _showSuccess = false;
    });

    try {
      final adminUser = FirebaseAuth.instance.currentUser!;
      final adminEmail = adminUser.email!;

      // Reauthenticate admin
      final cred = EmailAuthProvider.credential(
        email: adminEmail,
        password: _adminPasswordController.text,
      );
      await adminUser.reauthenticateWithCredential(cred);

      if (Platform.isWindows) {
        // 💻 On Windows, only save in Firestore (no FirebaseAuth teacher creation)
        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'teacher',
          'branch': hodBranch,
          'subjects': selectedSubjects,
          'createdBy': adminUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'note': 'Created in Windows environment (Auth not available)',
        });
      } else {
        // 📱 On Android/iOS, create real Firebase Auth teacher account
        final teacherCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final teacherId = teacherCredential.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(teacherId).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'teacher',
          'branch': hodBranch,
          'subjects': selectedSubjects,
          'createdBy': adminUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Re-login admin
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: _adminPasswordController.text.trim(),
        );
      }

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _adminPasswordController.clear();
      selectedSubjects.clear();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = e.message ?? "Error registering teacher";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = "Unexpected error: $e";
      });
    }
  }
}