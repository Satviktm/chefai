import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeGenerator extends StatefulWidget {
  @override
  _RecipeGeneratorState createState() => _RecipeGeneratorState();
}

class _RecipeGeneratorState extends State<RecipeGenerator> {
  final TextEditingController _ingredientController = TextEditingController();
  String _recipe = '';
  bool _isLoading = false;

  String? _selectedType;
  String? _selectedDiet;
  String? _selectedCuisine;
  List<String> _selectedItems = [];

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
  final List<String> _dietaryPreferences = [
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Paleo',
  ];
  final List<String> _cuisinePreferences = [
    'Italian',
    'Mexican',
    'Indian',
    'Chinese',
    'Mediterranean',
    'American',
    'Thai',
  ];

  Future<String?> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }
    return null;
  }

  Future<List<String>> _getUserItems(String userId) async {
    try {
      final userContainersSnapshot = await FirebaseFirestore.instance
          .collection('containers')
          .doc(userId)
          .collection('userContainers')
          .get();
      return userContainersSnapshot.docs
          .map((doc) => doc['itemName'] as String)
          .toList();
    } catch (e) {
      print('Error fetching user items: $e');
      return [];
    }
  }

  Future<void> _saveRecipe() async {
  final userId = await _getUserId();
  if (userId == null || _recipe.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please log in and generate a recipe first.')),
    );
    return;
  }

  // Controller for the recipe title input
  final TextEditingController titleController = TextEditingController();

  // Show dialog to ask for recipe title
  final recipeTitle = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Save Recipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter a title for your recipe:'),
            SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Recipe Title',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog without saving
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Return the title when saving
              Navigator.of(context).pop(titleController.text.trim());
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );

  // If the user cancels the dialog, `recipeTitle` will be null
  if (recipeTitle == null || recipeTitle.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recipe title is required.')),
    );
    return;
  }

  try {
    // Save the recipe to Firestore
    await FirebaseFirestore.instance.collection('recipes').add({
      'userId': userId,
      'title': recipeTitle, // Add the title field to Firestore
      'recipe': _recipe, // Ensure that the recipe data is correctly set
      'timestamp': FieldValue.serverTimestamp(),
      'preferences': {
        'mealType': _selectedType ?? 'Any',
        'diet': _selectedDiet ?? 'Any',
        'cuisine': _selectedCuisine ?? 'Any',
      },
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recipe saved successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save recipe: $e')),
    );
  }
}


  Future<void> _generateRecipe() async {
    setState(() {
      _isLoading = true;
      _recipe = '';
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

      final ingredients = _ingredientController.text;
      final dietary = _selectedDiet ?? 'Any';
      final mealType = _selectedType ?? 'Any';
      final cuisine = _selectedCuisine ?? 'Any';
      final selectedItemsText = _selectedItems.join(', ');

      final chat = model.startChat(history: [
  Content.text(
    'Generate a step-by-step recipe with the following format:\n\n'
    '**Title:** The name of the recipe in bold text.\n'
    '**Ingredients:** A bulleted list of ingredients, neatly formatted.\n'
    '**Making Procedure:** Clearly numbered steps with appropriate spacing.\n'
    '**Nutrition Value:** A summary of the recipe\'s nutrition information in a readable format.\n\n'
    'The recipe should include:\n'
    '- Meal type: $mealType\n'
    '- Dietary preference: $dietary\n'
    '- Cuisine type: $cuisine\n'
    '- Ingredients: $ingredients\n'
    '- Additional selected items: $selectedItemsText\n\n'
    'Ensure no special symbols like asterisks (*) or HTML tags (<br>) are used. Format everything cleanly and neatly for user display.'
  ),
]);

      final response = await chat.sendMessage(Content.text('Recipe request'));
      final rawResponse = response.text ?? 'No recipe found';
      final sanitizedResponse = rawResponse
      .replaceAll('*', '')
      .replaceAll('<br>', '\n')
      .trim();

      setState(() {
        _recipe = sanitizedResponse;
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
        title: const Text('Recipe Generator'),
        backgroundColor: Color.fromARGB(255, 0, 75, 10), // Dark Green
      ),
      body: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData) {
            return const Center(
              child: Text('No user logged in. Please log in.'),
            );
          }

          final userId = userSnapshot.data!;
          return FutureBuilder<List<String>>(
            future: _getUserItems(userId),
            builder: (context, itemSnapshot) {
              if (itemSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!itemSnapshot.hasData || itemSnapshot.data!.isEmpty) {
                return _buildManualRecipeForm(); // No items, show manual input
              }

              final userItems = itemSnapshot.data!;

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ Color.fromARGB(255, 0, 82, 5),Color.fromARGB(255, 255, 255, 255)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '"No idea what to cook? We\'ve got your back!"',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter ingredients and select items to generate an AI-powered recipe:',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ingredientController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          hintText:
                              'Enter ingredients (e.g., tomato, onion, chicken)',
                        ),
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        hint: 'Select Meal Type',
                        value: _selectedType,
                        items: _mealTypes,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedType = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        hint: 'Select Dietary Preference',
                        value: _selectedDiet,
                        items: _dietaryPreferences,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDiet = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        hint: 'Select Cuisine Preference',
                        value: _selectedCuisine,
                        items: _cuisinePreferences,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCuisine = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ...userItems.map((item) => CheckboxListTile(
                            title: Text(item),
                            value: _selectedItems.contains(item),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItems.add(item);
                                } else {
                                  _selectedItems.remove(item);
                                }
                              });
                            },
                          )),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _generateRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 0, 99, 7),
                                Color.fromARGB(255, 255, 255, 255),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                                color: Color.fromARGB(255, 0, 55, 20), width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: BoxConstraints(
                              minHeight: 50,
                              minWidth: 150,
                            ),
                            child: Text(
                              'Generate Recipe',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                      ],
                      const SizedBox(height: 16),
                      if (_recipe.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveRecipe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Save Recipe',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 76, 27),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255).withOpacity(0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color.fromARGB(255, 0, 88, 18).withOpacity(0),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _recipe,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      hint: Text(hint, style: GoogleFonts.nunito(fontSize: 16)),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: GoogleFonts.nunito(fontSize: 16)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildManualRecipeForm() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 0, 55, 29), Color.fromARGB(255, 255, 255, 255)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '"No idea what to cook? We\'ve got your back!"',
              style: GoogleFonts.nunito(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter ingredients to generate an AI-powered recipe:',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                hintText: 'Enter ingredients (e.g., tomato, onion, chicken)',
              ),
              style: GoogleFonts.nunito(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              hint: 'Select Meal Type',
              value: _selectedType,
              items: _mealTypes,
              onChanged: (newValue) {
                setState(() {
                  _selectedType = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              hint: 'Select Dietary Preference',
              value: _selectedDiet,
              items: _dietaryPreferences,
              onChanged: (newValue) {
                setState(() {
                  _selectedDiet = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              hint: 'Select Cuisine Preference',
              value: _selectedCuisine,
              items: _cuisinePreferences,
              onChanged: (newValue) {
                setState(() {
                  _selectedCuisine = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 0, 62, 32),
                      Color.fromARGB(255, 255, 255, 255),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border:
                      Border.all(color: Color.fromARGB(255, 0, 75, 29), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(
                    minHeight: 50,
                    minWidth: 150,
                  ),
                  child: Text(
                    'Generate Recipe',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_recipe.isNotEmpty)
              _buildRecipeDisplay(_recipe),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDisplay(String recipe) {
    final lines = recipe.split('\n');
    String title = "Generated Recipe";
    String? preparationTime;
    List<String> ingredients = [];
    String? importantNote;

    final stepWidgets = <Widget>[];
    bool isIngredientsSection = false;

    for (final line in lines) {
      if (title == "Generated Recipe" && line.startsWith('##')) {
        title = line.replaceAll('##', '').trim();
      } else if (line.toLowerCase().contains('preparation time:')) {
        preparationTime = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('ingredients:')) {
        isIngredientsSection = true;
      } else if (isIngredientsSection && line.trim().isNotEmpty) {
        if (RegExp(r'^\d+\..*').hasMatch(line)) {
          isIngredientsSection = false;
        } else {
          ingredients.add(line.trim());
        }
      }

      if (!isIngredientsSection &&
          line.isNotEmpty &&
          RegExp(r'^\d+\.').hasMatch(line)) {
        final parts = line.split('. ');
        final stepNumber = '${parts.first.trim()}';
        final content =
            parts.length > 1 ? parts.sublist(1).join('. ').trim() : '';

        stepWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '$stepNumber $content',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        );
      } else if (line.contains('Note:') && importantNote == null) {
        importantNote = line;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 24, fontWeight: FontWeight.bold)),
        if (preparationTime != null)
          Text('Preparation time: $preparationTime',
              style: TextStyle(fontSize: 16)),
        if (ingredients.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Ingredients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...ingredients.map(
              (ingredient) => Text(ingredient, style: TextStyle(fontSize: 16))),
        ],
        if (importantNote != null) ...[
          const SizedBox(height: 8),
          Text(
            'Note: $importantNote',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 8),
        const Text('Steps:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...stepWidgets,
      ],
    );
  }
}
