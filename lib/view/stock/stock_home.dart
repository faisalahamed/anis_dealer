import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class StockHome extends StatefulWidget {
  const StockHome({super.key});

  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;
  String _sortField = 'name';

  int _compareRows(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    String field,
    bool ascending,
  ) {
    int result;
    if (field == 'count') {
      final aVal = (a[field] ?? 0) as int;
      final bVal = (b[field] ?? 0) as int;
      result = aVal.compareTo(bVal);
    } else {
      final aVal = (a[field] ?? '').toString().toLowerCase();
      final bVal = (b[field] ?? '').toString().toLowerCase();
      result = aVal.compareTo(bVal);
    }
    return ascending ? result : -result;
  }

  void _onSort(int columnIndex, String field, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortField = field;
      _sortAscending = ascending;
    });
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
      appBar: AppBar(title: Text('Stock Management')),
      body: ScrollConfiguration(
        behavior: const _AppScrollBehavior(),
        child: StreamBuilder<QuerySnapshot>(
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
              ..sort((a, b) => _compareRows(a, b, _sortField, _sortAscending));

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
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      columns: [
                        DataColumn(label: Text('Stock ID')),
                        // DataColumn(label: Text('Model ID')),
                        DataColumn(
                          label: const Text('Mobile Name'),
                          onSort: (columnIndex, ascending) =>
                              _onSort(columnIndex, 'name', ascending),
                        ),
                        DataColumn(
                          label: const Text('Color'),
                          onSort: (columnIndex, ascending) =>
                              _onSort(columnIndex, 'color', ascending),
                        ),
                        DataColumn(
                          label: const Text('Description'),
                          onSort: (columnIndex, ascending) =>
                              _onSort(columnIndex, 'description', ascending),
                        ),
                        DataColumn(
                          label: const Text('Stock Count'),
                          numeric: true,
                          onSort: (columnIndex, ascending) =>
                              _onSort(columnIndex, 'count', ascending),
                        ),
                      ],
                      rows: List.generate(rows.length, (index) {
                        final item = rows[index];
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            // DataCell(Text(item['modelId'] ?? '')),
                            DataCell(Text(item['name'] ?? '')),
                            DataCell(Text(item['color'] ?? '')),
                            DataCell(Text(item['description'] ?? '')),
                            DataCell(Text('${item['count'] ?? 0}')),
                          ],
                        );
                      }),
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
