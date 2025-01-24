import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/auth_pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/sub_pages/SavedRecipesPage.dart';
import 'package:myapp/sub_pages/DynamicCard.dart';
import 'package:myapp/pages/food_packet_detector.dart';
import 'package:myapp/pages/smart_container.dart';
import 'package:myapp/pages/smart_coffee_maker.dart';
import 'package:myapp/pages/recipe_generator.dart';
import 'package:google_fonts/google_fonts.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    HomeSection(),
    FoodPacketDetector(),
    RecipeGenerator(),
    SmartContainer(),
    SmartCoffeeMaker(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:  const Color.fromARGB(255, 103, 177, 113),
          elevation: 1, // Light shadow
          title: Text(
            widget.title,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: _pages.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Food Packet Detector',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Recipe Generator',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storage),
              label: 'Smart Container',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.coffee),
              label: 'Smart Coffee Maker',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Uniform light background
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/food_banner.png', // Add a relevant banner image in assets
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // Food Detector Section
              Card(
                elevation: 8, // Increased elevation for better shadow effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fastfood, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Food Detector',
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan and identify food items using AI-powered image recognition. '
                        'Simply take a photo or select an image from your gallery to get started.',
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(context, ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: Text(
                          'Take a Photo',
                          style: GoogleFonts.nunito(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 90),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: const Color.fromARGB(255, 103, 177, 113),
                          shadowColor: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(context, ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        label: Text(
                          'Upload from Gallery',
                          style: GoogleFonts.nunito(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 62),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: const Color.fromARGB(255, 103, 177, 113),
                          shadowColor: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Tip Section
              Card(
                elevation: 6, // Slightly stronger shadow for this card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Tip:',
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ensure good lighting and focus on the food item for the best results.',
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Go to Saved Recipes Section
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SavedRecipesPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 103, 177, 113),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    shadowColor: Colors.greenAccent,
                  ),
                  child: Text(
                    'Go to Saved Recipes',
                    style: GoogleFonts.nunito(fontSize: 16, color: Colors.white),
                  ),
                ),
                
              ),
              // Dynamic Text Card
              DynamicCard(), // Add your DynamicCard widget
        const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      _classifyImage(image.path, 'home', context);
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _classifyImage(
      String imagePath, String view, BuildContext context) async {
    _showLoadingDialog(context,
        'Analyzing... Getting closer to finding out what\'s on your plate!');

    try {
      final File imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 100},
              {"type": "OBJECT_LOCALIZATION", "maxResults": 100},
              {"type": "IMAGE_PROPERTIES", "maxResults": 1},
              {"type": "LOGO_DETECTION", "maxResults": 5},
            ]
          }
        ]
      });

      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyBLBi64oSy6dYRNksjWG6hvzbUjJn_FuYM'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      Navigator.of(context).pop(); // Dismiss loading dialog

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final labels = data['responses'][0]['labelAnnotations'] ?? [];
        final objects =
            data['responses'][0]['localizedObjectAnnotations'] ?? [];
        final imageProperties =
            data['responses'][0]['imagePropertiesAnnotation'] ?? {};

        final List<dynamic> colors = imageProperties['dominantColors'] != null
            ? imageProperties['dominantColors']['colors']
            : [];
        List<String> colorNames = colors.map((color) {
          final rgbColor = color['color'];
          return 'R:${rgbColor['red']}, G:${rgbColor['green']}, B:${rgbColor['blue']}';
        }).toList();

        List<String> foodLabels = [];
        for (var label in labels) {
          final description = label['description'];
          if (description.toLowerCase().contains('food') ||
              description.toLowerCase().contains('dish')) {
            continue;
          }
          foodLabels.add(description);
          if (foodLabels.length >= 20) break;
        }

        for (var object in objects) {
          final objectDescription = object['name'];
          foodLabels.add(objectDescription);
          if (foodLabels.length >= 3) break;
        }

        String detectedItem =
            foodLabels.isNotEmpty ? foodLabels.join(', ') : 'Generic food';
        detectedItem += colorNames.isNotEmpty
            ? ' with colors: ${colorNames.join(', ')}'
            : '';

        final info = await _generateFoodInfo(detectedItem);
        _showClassificationResult(info, context);
      } else {
        if (response.statusCode == 403) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Access forbidden: Check your API key and permissions.')),
          );
        } else {
          throw Exception('Failed to classify image: ${response.reasonPhrase}');
        }
      }
    } catch (error) {
      Navigator.of(context).pop(); // Dismiss loading dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

Future<String> _generateFoodInfo(String detectedItem) async {
  try {
    const String geminiApiKey = 'AIzaSyAWZ-zZ55ZxOQt9dsaU4962KbIOtdqPAko';
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        maxOutputTokens: 1024,
        responseMimeType: 'text/plain',
      ),
    );

    final chat = model.startChat(history: [
      Content.text(
          'Given the item "$detectedItem"'
          'Generate the text with the following format:\n\n'
    '**Title:** The name of the recipe in bold text.\n'
    '**Nutrition Value:** A summary of the item\'s nutrition information in a readable format.\n\n'
    '**History:** A summary of the item\'s history in a readable format.\n\n'
    'Ensure no special symbols like asterisks (*) or HTML tags (<br>) are used. Format everything cleanly and neatly for user display.'),
      
    ]);

    final response =
        await chat.sendMessage(Content.text('food request'));

    
      final rawResponse = response.text ?? 'No recipe found';
      final sanitizedResponse = rawResponse
      .replaceAll('*', '')
      .replaceAll('<br>', '\n')
      .trim();
    return sanitizedResponse ;
  } catch (error) {
    print('Error in generating food info: $error');
    return 'Error generating food information: $error';
  }
}
  void _showClassificationResult(String info, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Food Analysis'),
          content: SingleChildScrollView(
            child: Text(info),
          ),
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