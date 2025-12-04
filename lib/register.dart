import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _adminSecretController = TextEditingController();

  String _selectedRole = 'student';
  String? _selectedBranch;
  List<String> _branchList = [];

  bool _passwordVisible = false;
  bool _showError = false;
  bool _showSuccess = false;
  String _errorMessage = '';

  // Color definitions
  Color primaryGreen = const Color(0xFF006400);
  Color lightGreen = const Color(0xFFE8F5E8);
  Color darkGreen = const Color(0xFF004D00);

  static const String ADMIN_SECRET_CODE = "SCOE@2025"; // <-- change before deploying

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    final snapshot = await FirebaseFirestore.instance.collection('branch').get();
    setState(() {
      _branchList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Register User",
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
                    Icons.person_add,
                    color: primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create New Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                    ),
                  ),
                  Text(
                    "Register new admin or student users",
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
              labelText: "Password",
              isVisible: _passwordVisible,
              onToggleVisibility: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
            const SizedBox(height: 16),

            // Role Dropdown
            _buildDropdown(
              value: _selectedRole,
              items: ['admin', 'student'],
              labelText: "Select Role",
              icon: Icons.people_outline,
            ),
            const SizedBox(height: 16),

            // Branch Dropdown
            _buildBranchDropdown(),
            const SizedBox(height: 16),

            // Admin secret input (only for admin role)
            if (_selectedRole == 'admin')
              _buildTextField(
                controller: _adminSecretController,
                labelText: "Enter Admin Secret Code",
                icon: Icons.security_outlined,
                isSecret: true,
              ),

            const SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Register",
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
                        "User registered successfully",
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
    bool isSecret = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isSecret,
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String labelText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((role) => DropdownMenuItem(
          value: role,
          child: Text(
            role.toUpperCase(),
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ))
            .toList(),
        onChanged: (value) => setState(() => _selectedRole = value!),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: darkGreen.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dropdownColor: lightGreen,
        icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
        style: TextStyle(color: darkGreen, fontSize: 14),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedBranch,
        items: _branchList
            .map((branch) => DropdownMenuItem(
          value: branch,
          child: Text(
            branch,
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ))
            .toList(),
        onChanged: (value) => setState(() => _selectedBranch = value),
        decoration: InputDecoration(
          labelText: "Select Branch",
          labelStyle: TextStyle(color: darkGreen.withOpacity(0.7)),
          prefixIcon: Icon(Icons.business_outlined, color: primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dropdownColor: lightGreen,
        icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
        style: TextStyle(color: darkGreen, fontSize: 14),
      ),
    );
  }

  Future<void> _registerUser() async {
    setState(() {
      _showError = false;
      _showSuccess = false;
      _errorMessage = '';
    });

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedBranch == null) {
      setState(() {
        _showError = true;
        _errorMessage = "All fields including branch are required.";
      });
      return;
    }

    if (_selectedRole == 'admin' &&
        _adminSecretController.text.trim() != ADMIN_SECRET_CODE) {
      setState(() {
        _showError = true;
        _errorMessage = "Invalid admin secret code.";
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'branch': _selectedBranch,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _showSuccess = true;
      });

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _adminSecretController.clear();
      _selectedBranch = null;
      _selectedRole = 'student';
    } on FirebaseAuthException catch (e) {
      setState(() {
        _showError = true;
        _errorMessage = e.message ?? "Error registering user";
      });
    } catch (e) {
      setState(() {
        _showError = true;
        _errorMessage = "Unexpected error: $e";
      });
    }
  }
}