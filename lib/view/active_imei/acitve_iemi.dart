import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ActiveImeiHome extends StatefulWidget {
  const ActiveImeiHome({super.key});

  @override
  State<ActiveImeiHome> createState() => _ActiveImeiHomeState();
}

class _ActiveImeiHomeState extends State<ActiveImeiHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();
  final Set<String> _selectedRows = <String>{};

  @override
  void dispose() {
    _hController.dispose();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active IMEI')),
      body: ScrollConfiguration(
        behavior: const _AppScrollBehavior(),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('sales')
              .orderBy('selling_date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No Records Found'));
            }

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
                          DataColumn(label: Text('sl')),
                          DataColumn(label: Text('IEMI')),
                          DataColumn(label: Text('Customer name')),
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('checkbox')),
                        ],
                        rows: List.generate(docs.length, (index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final isSelected = _selectedRows.contains(doc.id);
                          return DataRow(
                            selected: isSelected,
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text('${data['f_iemi'] ?? ''}')),
                              DataCell(
                                Text('${data['f_customer_name'] ?? ''}'),
                              ),
                              DataCell(
                                Text('${data['f_customer_code_name'] ?? ''}'),
                              ),
                              DataCell(
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedRows.add(doc.id);
                                      } else {
                                        _selectedRows.remove(doc.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
