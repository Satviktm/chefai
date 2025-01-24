import 'package:flutter/material.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/auth_pages/login_page.dart';
import 'package:myapp/pages/home_page.dart'; // Assuming this is the home page after login

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chef AI',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 0, 75, 10), // Zomato Red
        scaffoldBackgroundColor: Colors.white, // Clean white background
        fontFamily: 'Roboto', // Modern sans-serif font
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
          bodyLarge: TextStyle(
              fontSize: 16.0, color: Colors.grey), // For descriptions and details
          titleMedium: TextStyle(fontSize: 14.0, color: Colors.black),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor:  Color.fromARGB(255, 0, 75, 10), // Red app bar
          foregroundColor: Colors.white, // White text/icons
          elevation: 2,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color.fromARGB(255, 0, 75, 10), // Zomato Red buttons
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 0, 75, 10),
            foregroundColor: Colors.white,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shadowColor: Colors.grey[300],
          elevation: 4,
          margin: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 115, 255, 134), // Soft red
            Color.fromARGB(255, 198, 255, 236), // Light pink
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If a user is signed in, show the main/home page
          if (snapshot.hasData) {
            return const MyHomePage(
                title:
                    'Chef AI'); // Replace with your home page widget
          }
          // If no user is signed in, show the login page
          return const LoginPage();
        },
      ),
    );
  }
}
