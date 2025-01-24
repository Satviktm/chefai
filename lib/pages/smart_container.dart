import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/sub_pages/ItemNamesPage.dart';



class SmartContainer extends StatefulWidget {
  const SmartContainer({super.key});

  @override
  _SmartContainerState createState() => _SmartContainerState();
}

class _SmartContainerState extends State<SmartContainer> {
  String blynkAuthToken = "X1qr_tslockGnxDJYXhElT439B5g1723"; // Replace with your actual Blynk auth token
  List<ContainerData> containers = []; // List to store container data
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser!.uid; // Get the current user's ID
    fetchContainers(); // Load user's containers
  }

  // Function to fetch user's containers from Firestore
  Future<void> fetchContainers() async {
    final containerDocs = await _firestore.collection('containers')
        .doc(userId)
        .collection('userContainers')
        .get();

    setState(() {
      containers = containerDocs.docs.map((doc) => ContainerData.fromMap(doc.data())).toList();
    });

    // Now create a new collection for each item in the containers list
    for (var container in containers) {
      // Create a new collection with the item name (can use 'itemName' as document name or as a collection)
      await _firestore.collection('users')
          .doc(userId)  // User's specific document
          .collection(container.itemName)  // Collection with the item name
          .doc(container.id)  // Each container will be a document under this collection
          .set({
            'quantity': container.quantity,
            'unit': container.unit,
            'expirationDate': container.expirationDate,
            'sensorPort': container.sensorPort,
            'sensorData': container.sensorData,
            'timestamp': container.timestamp,
          });
    }
  }

  // Function to fetch sensor data for a given container
  Future<void> fetchSensorData(int index) async {
    final url = Uri.parse(
      "http://blynk.cloud/external/api/get?token=$blynkAuthToken&V${containers[index].sensorPort}"
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          containers[index].sensorData = response.body; // Update distance data
          // Update the sensor data in Firestore
          _firestore.collection('containers').doc(userId).collection('userContainers').doc(containers[index].id).update({'sensorData': containers[index].sensorData});
        });

        // Check if the sensor reading is below 2
        double sensorValue = double.tryParse(containers[index].sensorData) ?? 0.0;
        if (sensorValue < 2) {
          // Show warning if the reading is below 2
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Warning: Refill the container ${containers[index].itemName}.')),
          );
        }
      } else {
        setState(() {
          containers[index].sensorData = "Error: Unable to fetch data";
        });
      }
    } catch (e) {
      setState(() {
        containers[index].sensorData = "Error: ${e.toString()}";
      });
    }
  }

  // Function to display a dialog to add a new container
  Future<void> _addContainer() async {
    final newContainer = await showDialog<ContainerData>(
      context: context,
      builder: (BuildContext context) {
        return AddContainerDialog();
      },
    );

    if (newContainer != null) {
      // Check if the expiration date is valid
      DateTime expirationDate = DateTime.parse(newContainer.expirationDate);
      DateTime now = DateTime.now();

      if (expirationDate.isBefore(now)) {
        // Show warning if the expiration date is already passed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot add container. Expiration date has passed.')),
        );
        return;
      }

      // Show warning if the expiration date is within 5 days
      if (expirationDate.isBefore(now.add(Duration(days: 5)))) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Warning'),
              content: const Text('The expiration date is within 5 days. Do you want to proceed?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        );

        if (shouldProceed != true) return; // User chose not to proceed
      }

      setState(() {
        containers.add(newContainer); // Add the new container to the list
        fetchSensorData(containers.length - 1); // Fetch sensor data for the new container
      });

      // Store the new container in Firestore with a timestamp
      await _firestore.collection('containers').doc(userId).collection('userContainers').doc(newContainer.id).set(newContainer.toMap());

      // Create the new collection for the added container item name
      await _firestore.collection('users')
          .doc(userId)  // User's specific document
          .collection(newContainer.itemName)  // Collection with the item name
          .doc(newContainer.id)  // Each container will be a document under this collection
          .set({
            'quantity': newContainer.quantity,
            'unit': newContainer.unit,
            'expirationDate': newContainer.expirationDate,
            'sensorPort': newContainer.sensorPort,
            'sensorData': newContainer.sensorData,
            'timestamp': newContainer.timestamp,
          });
    }
  }

  // Function to delete a container
  Future<void> _deleteContainer(int index) async {
    final container = containers[index];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${container.itemName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        containers.removeAt(index); // Remove from local list
      });

      // Remove from Firestore
      await _firestore.collection('containers').doc(userId).collection('userContainers').doc(container.id).delete();

      // Also delete the container from the item collection
      await _firestore.collection('users')
          .doc(userId)
          .collection(container.itemName)
          .doc(container.id)
          .delete();
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Smart Container'),
      actions: [
        IconButton(
          icon: const Icon(Icons.list),
          tooltip: 'View Item Names',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemNamesPage(userId: userId),
              ),
            );
          },
        ),
      ],
    ),
    body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/scbg.gif'), // Replace with your image path
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          // How to Use Button
          Padding(
            padding: const EdgeInsets.all(26.0),
            child: ElevatedButton(
              onPressed: _showHowToUseDialog,
              child: const Text('How to Use!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 75, 31, 0), // Custom color for the button
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: containers.length,
              itemBuilder: (context, index) {
                final container = containers[index];
                return Card(
                  margin: const EdgeInsets.all(30.0),
                  child: Padding(
                    padding: const EdgeInsets.all(26.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Container ${index + 1}: ${container.itemName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Quantity: ${container.quantity} ${container.unit}'),
                        Text('Expiration Date: ${container.expirationDate}'),
                        const SizedBox(height: 8),
                        Text(
                          'Distance: ${container.sensorData}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => fetchSensorData(index),
                          child: const Text('Refresh Data'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _deleteContainer(index),
                          child: const Text('Delete Container'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 75, 31, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addContainer,
      child: const Icon(Icons.add),
      tooltip: 'Add Container',
    ),
  );
}

// Function to show the "How to Use" dialog
void _showHowToUseDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('How to Use'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('1. Add containers by clicking the "+" button.'),
            Text(' 2. Refresh sensor data by clicking "Refresh Data".'),
            Text(' 3. Delete containers by clicking "Delete Container".'),
            Text(' 4. View and manage items from the item names page.'),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

}

// Data model to represent each container
class ContainerData {
  final String id; // Unique identifier for the container
  final String itemName;
  final double quantity;
  final String unit;
  final String expirationDate;
  final int sensorPort; // Blynk virtual pin port for this container
  String sensorData; // Distance data from the sensor
  final Timestamp timestamp; // Timestamp for the creation time

  ContainerData({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
    required this.sensorPort,
    required this.timestamp,
    this.sensorData = 'Loading...',
  });

  // Method to convert a map into a ContainerData object
  factory ContainerData.fromMap(Map<String, dynamic> data) {
    return ContainerData(
      id: data['id'],
      itemName: data['itemName'],
      quantity: data['quantity'],
      unit: data['unit'],
      expirationDate: data['expirationDate'],
      sensorPort: data['sensorPort'],
      sensorData: data['sensorData'] ?? 'Loading...',
      timestamp: data['timestamp'], // Add this line
    );
  }

  // Method to convert a ContainerData object into a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': expirationDate,
      'sensorPort': sensorPort,
      'sensorData': sensorData,
      'timestamp': FieldValue.serverTimestamp(), // Add timestamp here
    };
  }
}

// Dialog widget to add a new container
class AddContainerDialog extends StatefulWidget {
  @override
  _AddContainerDialogState createState() => _AddContainerDialogState();
}

class _AddContainerDialogState extends State<AddContainerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  final TextEditingController _sensorPortController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Container'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _itemNameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) => value!.isEmpty ? 'Please enter item name' : null,
            ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Please enter quantity' : null,
            ),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
              validator: (value) => value!.isEmpty ? 'Please enter unit' : null,
            ),
            TextFormField(
              controller: _expirationDateController,
              decoration: const InputDecoration(labelText: 'Expiration Date (YYYY-MM-DD)'),
              validator: (value) => value!.isEmpty ? 'Please enter expiration date' : null,
            ),
            TextFormField(
              controller: _sensorPortController,
              decoration: const InputDecoration(labelText: 'Sensor Port'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Please enter sensor port' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newContainer = ContainerData(
                    id: DateTime.now().toString(), // Generate a unique ID for the container
                    itemName: _itemNameController.text,
                    quantity: double.parse(_quantityController.text),
                    unit: _unitController.text,
                    expirationDate: _expirationDateController.text,
                    sensorPort: int.parse(_sensorPortController.text),
                    timestamp: Timestamp.now(),
                  );
                  Navigator.of(context).pop(newContainer);
                }
              },
              child: const Text('Add Container'),
            ),
          ],
        ),
      ),
    );
  }
}
