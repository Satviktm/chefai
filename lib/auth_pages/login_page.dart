import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/pages/home_page.dart';
import 'package:myapp/auth_pages/register_page.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Cook with AI Home Page'),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          default:
            errorMessage = 'Invalid email or password.Please try again.';
        }
        _showErrorDialog(errorMessage);
      } catch (e) {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty.';
    }
    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
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
          // A semi-transparent dark overlay to make the text readable
          Container(
            color: Colors.black.withOpacity(0.1), // Adjust opacity to make image visible
          ),
          // Main UI content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 200), // Top spacing
                  Text(
                    'Chef AI',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing below the app name
                  Image.asset(
                    'assets/login_image.jpg', // Replace with your image path
                    height: 150, // Adjust height as needed
                    width: 150, // Adjust width as needed
                  ),
                  const SizedBox(height: 20),
                  // Email field with validation and custom styling
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
                      validator: _validateEmail,
                    ),
                  ),
                  // Password field with validation and custom styling
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Register',
                      style: GoogleFonts.poppins(color: Colors.white),
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