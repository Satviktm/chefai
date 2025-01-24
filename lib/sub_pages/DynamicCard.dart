import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DynamicCard extends StatefulWidget {
  const DynamicCard({Key? key}) : super(key: key);

  @override
  _DynamicCardState createState() => _DynamicCardState();
}

class _DynamicCardState extends State<DynamicCard> {
  late Timer _timer;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _dynamicTexts = [
  {
    'text': '"Cooking is an art; make every dish a masterpiece!"',
    'icon': Icons.brush, // Artistic icon
  },
  {
    'text': '"Did you know? Adding spices can enhance metabolism!"',
    'icon': Icons.local_fire_department, // Fire icon to represent metabolism
  },
  {
    'text': '"Fresh ingredients make all the difference!"',
    'icon': Icons.eco, // Eco icon for fresh ingredients
  },
  {
    'text': '"A balanced diet is a recipe for a healthy life!"',
    'icon': Icons.balance, // Balance icon
  },
  {
    'text': '"Every recipe tells a story—what’s yours?"',
    'icon': Icons.book, // Book icon for storytelling
  },
  {
    'text': '"A sprinkle of love is the secret ingredient to any dish!"',
    'icon': Icons.favorite, // Heart icon
  },
  {
    'text': '"Every meal is a chance to create something extraordinary!"',
    'icon': Icons.star, // Star icon for extraordinary
  },
  {
    'text': '"Cooking connects hearts, one recipe at a time!"',
    'icon': Icons.people, // People icon for connection
  },
];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _dynamicTexts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
 Widget build(BuildContext context) {
  return Card(
    color: Colors.orange, // Set the card background color to black
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            _dynamicTexts[_currentIndex]['icon'],
            color: Colors.black, // Icon color
            size: 36, // Icon size
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dynamicTexts[_currentIndex]['text'],
              style: GoogleFonts.itim(
                fontSize: 18,
                color: Colors.black, // Set the text color to white
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
