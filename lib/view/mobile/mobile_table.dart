import 'package:anis_dealer/view/mobile/add_new_mobile_multi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';

class MobileTableView extends StatefulWidget {
  const MobileTableView({super.key});

  @override
  State<MobileTableView> createState() => _MobileTableViewState();
}

class _MobileTableViewState extends State<MobileTableView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  String _formatDate(DateTime date) {
    return DateFormat('d MMM h:mm a').format(date);
  }

  String _createdAtToString(dynamic value) {
    if (value is Timestamp) {
      return _formatDate(value.toDate().toLocal());
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mobile Stock')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (_) => const AddNewMobilePage(),
                //   ),
                // );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddNewMobileMultiPage(),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text('New Mobile'),
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AppScrollBehavior(),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('mobiles')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Mobiles Found'));
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
                            columns: const [
                              DataColumn(label: Text('Mobile ID')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('IEMI')),
                              DataColumn(label: Text('Model ID')),
                              DataColumn(label: Text('Mobile Name')),
                              DataColumn(label: Text('Color')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Buy Price')),
                              DataColumn(label: Text('Est. Sell Price')),
                              DataColumn(label: Text('Sold')),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;

                              return DataRow(
                                cells: [
                                  DataCell(Text(doc.id)),
                                  DataCell(
                                    Text(_createdAtToString(data['createdAt'])),
                                  ),
                                  DataCell(Text('${data['iemi'] ?? ''}')),
                                  DataCell(Text('${data['modelId'] ?? ''}')),
                                  DataCell(Text('${data['name'] ?? ''}')),
                                  DataCell(Text('${data['color'] ?? ''}')),
                                  DataCell(Text('${data['description'] ?? ''}')),
                                  DataCell(Text('${data['buyPrice'] ?? ''}')),
                                  DataCell(
                                    Text(
                                        '${data['estimatedSellingPrice'] ?? ''}'),
                                  ),
                                  DataCell(
                                    Text((data['isSold'] ?? false)
                                        ? 'Yes'
                                        : 'No'),
                                  ),
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
