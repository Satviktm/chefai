import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AskAIChefPage extends StatefulWidget {
  const AskAIChefPage({super.key});

  @override
  _AskAIChefPageState createState() => _AskAIChefPageState();
}

class _AskAIChefPageState extends State<AskAIChefPage> {
  final TextEditingController _ingredientController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ContainerData> containers = [];
  String? _recipe = 'Your recipe will appear here';
  String? _recipeImage;
  bool _isLoading = false;

  String? _selectedType;
  String? _selectedDiet;
  String? _selectedCuisine;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
  final List<String> _dietaryPreferences = [
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Paleo'
  ];
  final List<String> _cuisinePreferences = [
    'Italian',
    'Mexican',
    'Indian',
    'Chinese',
    'Mediterranean',
    'American',
    'Thai'
  ];

  @override
  void initState() {
    super.initState();
    fetchContainers();
  }

  Future<void> fetchContainers() async {
    final userId = 'user-id'; // Replace with actual user ID
    final containerDocs = await _firestore.collection('containers').doc(userId).collection('userContainers').get();

    setState(() {
      containers = containerDocs.docs.map((doc) => ContainerData.fromMap(doc.data())).toList();
    });
  }

  Future<void> _generateRecipe() async {
    setState(() {
      _isLoading = true;
      _recipe = null;
      _recipeImage = null;
    });

    try {
      const String geminiApiKey = 'AIzaSyAWZ-zZ55ZxOQt9dsaU4962KbIOtdqPAko';
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.9,
          topP: 0.95,
          maxOutputTokens: 1024,
          responseMimeType: 'text/plain',
        ),
      );

      // Combine ingredients from containers
      final ingredients = containers;
      final dietary = _selectedDiet ?? 'Any';
      final mealType = _selectedType ?? 'Any';
      final cuisine = _selectedCuisine ?? 'Any';

      final chat = model.startChat(history: [
        Content.text(
          'Generate a $mealType recipe that is $dietary and $cuisine based on the following ingredients: $ingredients.',
        ),
      ]);

      final response = await chat.sendMessage(Content.text('Recipe request'));
      setState(() {
        _recipe = response.text ?? 'No recipe found';
        _recipeImage = ''; // Replace with image URL if available
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _recipe = 'Error generating recipe: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI Chef'),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightGreenAccent, Color.fromARGB(255, 18, 107, 0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ask AI Chef',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter ingredients to generate an AI-powered recipe:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ingredientController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter additional ingredients (e.g., tomato, onion, chicken)',
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                hint: 'Select Meal Type',
                value: _selectedType,
                items: _mealTypes,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                hint: 'Select Dietary Preference',
                value: _selectedDiet,
                items: _dietaryPreferences,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDiet = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                hint: 'Select Cuisine Preference',
                value: _selectedCuisine,
                items: _cuisinePreferences,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCuisine = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                ),
                child: const Text('Generate Recipe'),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_recipe != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _recipe!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      if (_recipeImage != null && _recipeImage!.isNotEmpty)
                        Image.network(
                          _recipeImage!,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        hint: Text(hint),
        value: value,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<T>>((T value) {
          return DropdownMenuItem<T>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }
}

// Define your ContainerData class to map Firestore data
class ContainerData {
  final String ingredient;

  ContainerData({required this.ingredient});

  factory ContainerData.fromMap(Map<String, dynamic> data) {
    return ContainerData(
      ingredient: data['ingredient'] ?? '',
    );
  }
}
