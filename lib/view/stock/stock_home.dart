import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockHome extends StatefulWidget {
  const StockHome({super.key});

  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stock Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('mobiles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Stock Found'));
          }

          final Map<String, Map<String, dynamic>> grouped = {};
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final isSold = (data['isSold'] ?? false) == true;
            if (isSold) continue;
            final modelId = (data['modelId'] ?? '').toString();
            if (modelId.isEmpty) continue;

            final existing = grouped[modelId];
            if (existing == null) {
              grouped[modelId] = {
                'modelId': modelId,
                'name': (data['name'] ?? '').toString(),
                'color': (data['color'] ?? '').toString(),
                'description': (data['description'] ?? '').toString(),
                'count': 1,
              };
            } else {
              existing['count'] = (existing['count'] as int) + 1;
            }
          }

          final rows = grouped.values.toList()
            ..sort((a, b) => a['modelId'].compareTo(b['modelId']));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Stock ID')),
                  DataColumn(label: Text('Model ID')),
                  DataColumn(label: Text('Mobile Name')),
                  DataColumn(label: Text('Color')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Stock Count')),
                ],
                rows: List.generate(rows.length, (index) {
                  final item = rows[index];
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(item['modelId'] ?? '')),
                      DataCell(Text(item['name'] ?? '')),
                      DataCell(Text(item['color'] ?? '')),
                      DataCell(Text(item['description'] ?? '')),
                      DataCell(Text('${item['count'] ?? 0}')),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}
