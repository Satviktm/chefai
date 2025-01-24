import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class SmartCoffeeMaker extends StatefulWidget {
  const SmartCoffeeMaker({super.key});

  @override
  State<SmartCoffeeMaker> createState() => _SmartCoffeeMakerState();
}

class _SmartCoffeeMakerState extends State<SmartCoffeeMaker> {
  final String blynkAuthToken = "X1qr_tslockGnxDJYXhElT439B5g1723"; // Replace with your Blynk Auth Token
  bool pump1State = false; // Track state of Pump 1
  bool pump2State = false; // Track state of Pump 2

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructionsPopup());
  }

  // Function to display the instructions popup
  void _showInstructionsPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 75, 31, 0),
            ),
          ),
          content: const Text(
            '1. Ensure the smart coffee machine is powered.\n'
            '2. Ensure the milk and decoction tank are filled up to the mark.\n'
            '3. Make sure you have placed your cup at the right spot.\n'
            '4. Sit back and relax while the coffee is poured into the cup with just two clicks.',
            style: TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 59, 34, 9),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 75, 31, 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to toggle the pump state via Blynk
  Future<void> togglePump(int pumpNumber, bool state) async {
    final String virtualPin = pumpNumber == 1 ? "V1" : "V2";
    final String url =
        "https://blynk.cloud/external/api/update?token=$blynkAuthToken&$virtualPin=${state ? 1 : 0}";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          if (pumpNumber == 1) {
            pump1State = state;
          } else {
            pump2State = state;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pump $pumpNumber turned ${state ? "ON" : "OFF"}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to control the pump")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to brew coffee
  Future<void> brewCoffee() async {
    // Turn both pumps ON
    await togglePump(1, true); // Turn on Pump 1 (e.g., Milk)
    await togglePump(2, true); // Turn on Pump 2 (e.g., Water with coffee powder)

    // Delay for Pump 1 (Milk) - 3 seconds
    Timer(const Duration(seconds: 3), () async {
      await togglePump(1, false);
      await togglePump(2, false); // Turn off Pump 1
    });

    // Delay for Pump 2 (Water) - 1 second
    Timer(const Duration(seconds: 2), () async {
      await togglePump(2, false); // Turn off Pump 2
    });
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24), // Add the icon
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 5.0,
                  color: Colors.black,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color.fromARGB(255, 75, 31, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Coffee Maker'),
        backgroundColor: const Color.fromARGB(255, 75, 31, 0),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/coffee_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // White card overlay
          Center(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 244, 198).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    '"Innovation in Every Sip"',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 75, 31, 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Brew the perfect cup of coffee with ease.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 59, 34, 9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Hot Milk',
                    value: pump1State,
                    onChanged: (value) => togglePump(1, value),
                    icon: Icons.local_drink,
                  ),
                  const SizedBox(height: 5),
                  _buildSwitchTile(
                    title: 'Decoction',
                    value: pump2State,
                    onChanged: (value) => togglePump(2, value),
                    icon: Icons.coffee,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: brewCoffee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 75, 31, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Brew Coffee',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
