import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:SCOE/adminscreen.dart';
import 'package:SCOE/main.dart';
import 'package:SCOE/register.dart';
import 'package:SCOE/studentscreen.dart';
import 'package:SCOE/teacherscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _showError = false;

  @override
  Widget build(BuildContext context)
  {
    const darkGreen = Color(0xFF006400);
    const mediumGreen = Color(0xFF4CAF50);
    const surfaceColor = Color(0xFFF5FDF5);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Center(
              child: SizedBox(
                height: 200,
                width : 220,
                child : Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.school, size: 120, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Welcome Back",
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: darkGreen),
            ),
            const SizedBox(height: 8),
            Text(
              "Login to continue",
              style: TextStyle(fontSize: 16, color: mediumGreen),
            ),
            const SizedBox(height: 32),

            // Card for email/password
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darkGreen),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email address",
                        prefixIcon: const Icon(Icons.email, color: darkGreen),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: mediumGreen),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darkGreen),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock, color: darkGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: darkGreen,
                          ),
                          onPressed: () {
                            setState(
                                    () => _passwordVisible = !_passwordVisible);
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: mediumGreen),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darkGreen),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error
                    if (_showError)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "Incorrect email or password",
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _showError = false);
                          try {
                            final userCredential = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                            final uid = userCredential.user!.uid;

                            // Get user document from Firestore
                            final doc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .get();

                            if (!doc.exists) {
                              setState(() => _showError = true);
                              return;
                            }

                            final userData = doc.data()!;
                            final role = userData['role'];
                            final branch = userData['branch']; // get branch too

                            // You can pass branch to the next screen if needed
                            if (role == 'admin') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboard(),
                                ),
                              );
                            } else if (role == 'teacher') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeacherHomeScreen(),
                                ),
                              );
                            } else if (role == 'student') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentHomeScreen(),
                                ),
                              );
                            } else {
                              setState(() => _showError = true);
                            }
                          } catch (e) {
                            setState(() => _showError = true);
                          }

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Navigate to Registration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
