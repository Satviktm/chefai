import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Update the user profile with the name
        await userCredential.user?.updateDisplayName(_nameController.text.trim());

        Navigator.pop(context); // Go back to the login page after successful registration
      } catch (e) {
        String errorMessage;
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'This email address is already in use.';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is not valid.';
              break;
            case 'weak-password':
              errorMessage = 'The password is too weak.';
              break;
            default:
              errorMessage = 'An error occurred. Please try again.';
          }
        } else {
          errorMessage = e.toString();
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Failed'),
              content: Text(errorMessage),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image, fixed
          Positioned.fill(
            child: Image.asset(
              'assets/image3.png', // Background image path
              fit: BoxFit.cover,
            ),
          ),
          // Semi-transparent dark overlay to improve readability
          Container(
            color: Colors.black.withOpacity(0.1), // Dark overlay with opacity
          ),
          // Main UI content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 150), // Spacing at the top
                  Text(
                    'Register',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Image.asset(
                     'assets/login_image.jpg', // Replace with your image path
                      height: 150, // Adjust height as needed
                      width: 150, // Adjust width as needed
                   ),
                  
                  const SizedBox(height: 20), // Add spacing
                  // Name field
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.roboto(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: GoogleFonts.roboto(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.7),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorStyle: GoogleFonts.roboto(color: Colors.white), // White error text
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name cannot be empty.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10), // Add spacing
                  // Email field
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.roboto(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.roboto(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.7),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorStyle: GoogleFonts.roboto(color: Colors.white), // White error text
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email cannot be empty.';
                        }
                        if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(value)) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10), // Add spacing
                  // Password field
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: _passwordController,
                      style: GoogleFonts.roboto(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.roboto(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.7),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorStyle: GoogleFonts.roboto(color: Colors.white), // White error text
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty.';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Add spacing
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: _register,
                    child: Text(
                      'Register',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}