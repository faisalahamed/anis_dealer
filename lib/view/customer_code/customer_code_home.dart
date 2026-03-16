import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class CustomerCodeHome extends StatefulWidget {
  const CustomerCodeHome({super.key});

  @override
  State<CustomerCodeHome> createState() => _CustomerCodeHomeState();
}

class _CustomerCodeHomeState extends State<CustomerCodeHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  void _showAddCodeDialog() {
    final codeNameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Customer Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeNameController,
                decoration: const InputDecoration(labelText: 'Code Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
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
              if (codeNameController.text.isNotEmpty &&
                  codeController.text.isNotEmpty) {
                final docRef = _firestore.collection('customer_coode').doc();
                await docRef.set({
                  'code_id': docRef.id,
                  'code_name': codeNameController.text.trim(),
                  'code': codeController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCodeDialog(String docId, Map<String, dynamic> data) {
    final codeNameController = TextEditingController(
      text: '${data['code_name'] ?? ''}',
    );
    final codeController = TextEditingController(text: '${data['code'] ?? ''}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeNameController,
                decoration: const InputDecoration(labelText: 'Code Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
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
              if (codeNameController.text.isNotEmpty &&
                  codeController.text.isNotEmpty) {
                await _firestore
                    .collection('customer_coode')
                    .doc(docId)
                    .update({
                      'code_name': codeNameController.text.trim(),
                      'code': codeController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCode(String docId, String codeName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(codeName.isEmpty ? 'Delete Code' : codeName),
        content: const Text('Do you want to delete this code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _firestore.collection('customer_coode').doc(docId).delete();
    }
  }

  @override
  void dispose() {
    _hController.dispose();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Codes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddCodeDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Code'),
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AppScrollBehavior(),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('customer_coode')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Codes Found'));
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
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: DataTable(
                              columnSpacing: 24,
                              columns: const [
                                // DataColumn(label: Text('Code ID')),
                                DataColumn(label: Text('Code Name')),
                                // DataColumn(label: Text('Code')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DataRow(
                                  cells: [
                                    // DataCell(Text('${data['code_id'] ?? ''}')),
                                    DataCell(
                                      Text('${data['code_name'] ?? ''}'),
                                    ),
                                    // DataCell(Text('${data['code'] ?? ''}')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _showEditCodeDialog(
                                                  doc.id,
                                                  data,
                                                ),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteCode(
                                              doc.id,
                                              '${data['code_name'] ?? ''}',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
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
