import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';

class ModelView extends StatefulWidget {
  const ModelView({super.key});

  @override
  State<ModelView> createState() => _ModelViewState();
}

class _ModelViewState extends State<ModelView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  void _showAddModelDialog() {
    final nameController = TextEditingController();
    final colorController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Model'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Model Name'),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  colorController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                await _firestore.collection('models').add({
                  'name': nameController.text,
                  'color': colorController.text,
                  'description': descriptionController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Models')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddModelDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Model'),
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AppScrollBehavior(),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('models').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Models Found'));
                  }

                  final docs = snapshot.data!.docs;

                  return Scrollbar(
                    controller: _vController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _vController,
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        controller: _hController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _hController,
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 24,
                            columns: const [
                              // DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Model Name')),
                              DataColumn(label: Text('Color')),
                              DataColumn(label: Text('Description')),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;

                              return DataRow(
                                cells: [
                                  // DataCell(Text(doc.id)),
                                  DataCell(Text(data['name'] ?? '')),
                                  DataCell(Text(data['color'] ?? '')),
                                  DataCell(Text(data['description'] ?? '')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}
