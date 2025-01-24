import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemNamesPage extends StatelessWidget {
  final String userId; // User ID passed from the parent page

  const ItemNamesPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Names'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('containers')
            .doc(userId)
            .collection('userContainers')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No items found.'),
            );
          }

          final itemNames = snapshot.data!.docs
              .map((doc) => doc['itemName'] as String)
              .toList();

          return ListView.builder(
            itemCount: itemNames.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(itemNames[index]),
                leading: const Icon(Icons.kitchen),
              );
            },
          );
        },
      ),
    );
  }
}
