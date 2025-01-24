import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodPacketDetector extends StatelessWidget {
  const FoodPacketDetector({super.key});

 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Food Packet Detector',
        style: GoogleFonts.nunito(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 229, 238, 230), // Light text color
        ),
      ),
      backgroundColor: Color.fromARGB(255, 0, 75, 10), // Dark Green
    ),
    body: Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/fpbackground.gif', // Path to your background image
            fit: BoxFit.cover, // Ensure the image covers the screen
          ),
        ),
        // Gradient overlay for smooth fading effect (only on the background, not on buttons)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(0, 0, 0, 0), // Transparent
                  Color.fromARGB(139, 53, 99, 7), // Dark green with some opacity
                ],
              ),
            ),
          ),
        ),
        // Content area with padding
        Center(
          child: Padding(
            padding: const EdgeInsets.all(17.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Title Text with no fading effect
                  Text(
                    '"Unwrap the mystery of your food packets—because even your snacks deserve a little detective work!"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 75, 10), // Dark Green
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Description text with no fading effect
                  Text(
                    'Scan food packets using AI to detect barcodes, logos, and text. Gain insights and nutritional details!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 3, 11, 4), // Dark text
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Front View section styled as a smaller box (scrollable)
                  _buildButtonSection(context, "Front View", Icons.camera_front),
                  const SizedBox(height: 20),
                  // Back View section styled as a smaller box (scrollable)
                  _buildButtonSection(context, "Back View", Icons.camera_rear),
                  const SizedBox(height: 20),
                  // Info Card section
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper function for the Front/Back View button styling
Widget _buildButtonSection(BuildContext context, String title, IconData icon) {
  return GestureDetector(
    onTap: () => _pickImage(context, title),
    child: Container(
      height: 60, // Reduced height for the button section
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 75, 10), // Solid dark green color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5), // White border to make it look like a button
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white, // White text color
            ),
          ),
        ],
      ),
    ),
  );
}

// Info Card with fade effect
Widget _buildInfoCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color.fromARGB(140, 0, 75, 10), // Dark Green with opacity
      border: Border.all(color: Colors.white, width: 1.5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              'How it works:',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '1. Tap on "Front View" or "Back View" to scan the food packet.\n'
          '2. Capture an image and let the AI analyze it.\n'
          '3. Receive details like logos, text, and nutritional information.',
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Future<void> _pickImage(BuildContext context, String view) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(source: ImageSource.camera);

  if (image != null) {
    _classifyImage(image.path, view, context);
  }
}

void _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color.fromARGB(255, 0, 75, 10), // Dark Green
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _classifyImage(
      String imagePath, String view, BuildContext context) async {
    _showLoadingDialog(context,
        'Scanning the packet... Hang tight while we decode its secrets!');
try {
      final File imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 10},
              {"type": "TEXT_DETECTION", "maxResults": 10},
              {"type": "LOGO_DETECTION", "maxResults": 10}
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

      print('Vision API response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final labels = data['responses'][0]['labelAnnotations'] ?? [];
        final logos = data['responses'][0]['logoAnnotations'] ?? [];
        final texts = data['responses'][0]['textAnnotations'] ?? [];

        final detectedLabel =
            labels.isNotEmpty ? labels[0]['description'] : 'Generic food';
        final detectedLogo = logos.isNotEmpty ? logos[0]['description'] : '';
        final detectedText = texts.isNotEmpty ? texts[0]['description'] : '';

        final detectedItem = [detectedLabel, detectedLogo, detectedText]
            .where((e) => e.isNotEmpty)
            .join(', ');

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
          print('Failed response: ${response.body}');
          throw Exception('Failed to classify image: ${response.reasonPhrase}');
        }
      }
    } catch (error) {
      Navigator.of(context).pop(); // Dismiss loading dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      print('Error in classification: $error');
    }
  }

  void _showClassificationResult(String info, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 0, 75, 10), // Dark Green
          title: const Text(
            'Food Packet Analysis',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              info,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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
          'Given the food item "$detectedItem", provide detailed nutritional information, ingredients if known, and common uses for this type of product. Format the response with appropriate emojis for key information like calories 🍎, fats 🧈, and protein 💪. Remove any bullet points, asterisks, or other symbols and ensure proper alignment of the information. Leave a line after each sentence.'),
    ]);

     final response =
        await chat.sendMessage(Content.text('Nutrition and uses request'));

    print('Gemini API response: ${response.text}');

    // Format the response to ensure clean text with emojis
    String formattedResponse = response.text ?? 'No information found';

    // Replace unwanted characters, ensuring line breaks after each sentence
    formattedResponse = formattedResponse.replaceAll(RegExp(r'\*|\n'), ' ').trim();
    formattedResponse = formattedResponse.replaceAll(RegExp(r'(?<=\w[.!?])\s*(?=\w)'), '\n');

    return formattedResponse;
  } catch (error) {
    print('Error in generating food info: $error');
    return 'Error generating food information: $error';
  }
}
}