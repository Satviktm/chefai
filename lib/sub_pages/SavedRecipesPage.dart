import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedRecipesPage extends StatefulWidget {
  @override
  _SavedRecipesPageState createState() => _SavedRecipesPageState();
}

class _SavedRecipesPageState extends State<SavedRecipesPage> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance.collection('recipes').doc(recipeId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recipe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Saved Recipes')),
        body: Center(child: Text('Please log in to view your saved recipes.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Saved Recipes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No recipes saved yet.'));
          }

          final recipes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final data = recipe.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  title: Text(data['title'] ?? 'Untitled Recipe',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text(data['recipe'] ?? 'No recipe content available.'),
                      SizedBox(height: 5),
                      Text(
                        "Meal Type: ${data['preferences']['mealType'] ?? 'Any'}\n"
                        "Diet: ${data['preferences']['diet'] ?? 'Any'}\n"
                        "Cuisine: ${data['preferences']['cuisine'] ?? 'Any'}",
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete Recipe'),
                            content: Text('Are you sure you want to delete this recipe?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        _deleteRecipe(recipe.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
