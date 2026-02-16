import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:anis_dealer/view/mobile/add_new_mobile.dart';

class MobileTableView extends StatefulWidget {
  const MobileTableView({super.key});

  @override
  State<MobileTableView> createState() => _MobileTableViewState();
}

class _MobileTableViewState extends State<MobileTableView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddNewMobilePage(),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text('New Mobile'),
            ),
          ),
          Expanded(
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

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
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
                            DataCell(Text(_createdAtToString(data['createdAt']))),
                            DataCell(Text('${data['iemi'] ?? ''}')),
                            DataCell(Text('${data['modelId'] ?? ''}')),
                            DataCell(Text('${data['name'] ?? ''}')),
                            DataCell(Text('${data['color'] ?? ''}')),
                            DataCell(Text('${data['description'] ?? ''}')),
                            DataCell(Text('${data['buyPrice'] ?? ''}')),
                            DataCell(Text('${data['estimatedSellingPrice'] ?? ''}')),
                            DataCell(Text((data['isSold'] ?? false) ? 'Yes' : 'No')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
