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
  String _searchQuery = '';
  int _currentPage = 0;
  int _rowsPerPage = 10;

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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search Name / Color / Description',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 0;
                            });
                          },
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
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

                  var rows = grouped.values.toList()
                    ..sort(
                      (a, b) => _compareRows(
                        a,
                        b,
                        _sortField,
                        _sortAscending,
                      ),
                    );

                  final query = _searchQuery.trim().toLowerCase();
                  if (query.isNotEmpty) {
                    rows = rows.where((row) {
                      final name = (row['name'] ?? '').toString().toLowerCase();
                      final color = (row['color'] ?? '')
                          .toString()
                          .toLowerCase();
                      final desc = (row['description'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(query) ||
                          color.contains(query) ||
                          desc.contains(query);
                    }).toList();
                  }

                  if (rows.isEmpty) {
                    return const Center(child: Text('No Matching Stock Found'));
                  }

                  final totalRows = rows.length;
                  final totalPages = totalRows == 0
                      ? 1
                      : ((totalRows + _rowsPerPage - 1) ~/ _rowsPerPage);
                  final currentPage = _currentPage >= totalPages
                      ? totalPages - 1
                      : _currentPage;
                  final start = currentPage * _rowsPerPage;
                  final end = (start + _rowsPerPage) > totalRows
                      ? totalRows
                      : (start + _rowsPerPage);
                  final pageRows = rows.sublist(start, end);

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DataTable(
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _sortAscending,
                                columns: [
                                  DataColumn(label: Text('Stock ID')),
                                  // DataColumn(label: Text('Model ID')),
                                  DataColumn(
                                    label: const Text('Mobile Name'),
                                    onSort: (columnIndex, ascending) =>
                                        _onSort(
                                          columnIndex,
                                          'name',
                                          ascending,
                                        ),
                                  ),
                                  DataColumn(
                                    label: const Text('Color'),
                                    onSort: (columnIndex, ascending) =>
                                        _onSort(
                                          columnIndex,
                                          'color',
                                          ascending,
                                        ),
                                  ),
                                  DataColumn(
                                    label: const Text('Description'),
                                    onSort: (columnIndex, ascending) =>
                                        _onSort(
                                          columnIndex,
                                          'description',
                                          ascending,
                                        ),
                                  ),
                                  DataColumn(
                                    label: const Text('Stock Count'),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) =>
                                        _onSort(
                                          columnIndex,
                                          'count',
                                          ascending,
                                        ),
                                  ),
                                ],
                                rows: List.generate(pageRows.length, (index) {
                                  final item = pageRows[index];
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text('${start + index + 1}'),
                                      ),
                                      // DataCell(Text(item['modelId'] ?? '')),
                                      DataCell(Text(item['name'] ?? '')),
                                      DataCell(Text(item['color'] ?? '')),
                                      DataCell(Text(item['description'] ?? '')),
                                      DataCell(Text('${item['count'] ?? 0}')),
                                    ],
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Rows per page:'),
                                  DropdownButton<int>(
                                    value: _rowsPerPage,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 10,
                                        child: Text('10'),
                                      ),
                                      DropdownMenuItem(
                                        value: 20,
                                        child: Text('20'),
                                      ),
                                      DropdownMenuItem(
                                        value: 50,
                                        child: Text('50'),
                                      ),
                                      DropdownMenuItem(
                                        value: 500,
                                        child: Text('500'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _rowsPerPage = value;
                                        _currentPage = 0;
                                      });
                                    },
                                  ),
                                  Text('Page ${currentPage + 1} of $totalPages'),
                                  IconButton(
                                    tooltip: 'First page',
                                    onPressed: currentPage == 0
                                        ? null
                                        : () => setState(
                                              () => _currentPage = 0,
                                            ),
                                    icon: const Icon(Icons.first_page),
                                  ),
                                  IconButton(
                                    tooltip: 'Previous page',
                                    onPressed: currentPage == 0
                                        ? null
                                        : () => setState(
                                              () =>
                                                  _currentPage = currentPage - 1,
                                            ),
                                    icon: const Icon(Icons.navigate_before),
                                  ),
                                  IconButton(
                                    tooltip: 'Next page',
                                    onPressed:
                                        currentPage >= totalPages - 1
                                            ? null
                                            : () => setState(
                                                  () =>
                                                      _currentPage =
                                                          currentPage + 1,
                                                ),
                                    icon: const Icon(Icons.navigate_next),
                                  ),
                                  IconButton(
                                    tooltip: 'Last page',
                                    onPressed:
                                        currentPage >= totalPages - 1
                                            ? null
                                            : () => setState(
                                                  () =>
                                                      _currentPage =
                                                          totalPages - 1,
                                                ),
                                    icon: const Icon(Icons.last_page),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
