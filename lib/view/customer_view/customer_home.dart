import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Customer Mobile'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Customer Address'),
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
                  mobileController.text.isNotEmpty &&
                  addressController.text.isNotEmpty) {
                await _firestore.collection('customers').add({
                  'name': nameController.text,
                  'mobile': mobileController.text,
                  'address': addressController.text,
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
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddCustomerDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Customer'),
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AppScrollBehavior(),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('customers')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Customers Found'));
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
                              DataColumn(label: Text('Customer ID')),
                              DataColumn(label: Text('Customer Name')),
                              DataColumn(label: Text('Customer Mobile')),
                              DataColumn(label: Text('Customer Address')),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DataRow(
                                cells: [
                                  DataCell(Text(doc.id)),
                                  DataCell(Text(data['name'] ?? '')),
                                  DataCell(Text(data['mobile'] ?? '')),
                                  DataCell(Text(data['address'] ?? '')),
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
