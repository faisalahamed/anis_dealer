import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _showActivatedOnly = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredDocs = [];
  int _currentPage = 0;
  int _rowsPerPage = 10;

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate().toLocal();
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yy = dt.year.toString();
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dd/$mm/$yy $hh:$min';
    }
    return '';
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
      appBar: AppBar(title: const Text('Active IMEI')),
      body: ScrollConfiguration(
        behavior: const _AppScrollBehavior(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Show:'),
                  Switch(
                    value: _showActivatedOnly,
                    onChanged: (value) {
                      setState(() => _showActivatedOnly = value);
                    },
                  ),
                  Text(_showActivatedOnly ? 'Activated' : 'Inactive'),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final selected = _selectedRows.toSet();
                      if (selected.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No rows selected')),
                        );
                        return;
                      }

                      final batch = _firestore.batch();
                      for (final docId in selected) {
                        batch.update(
                          _firestore.collection('active_iemi').doc(docId),
                          {'is_activated': true},
                        );
                      }
                      await batch.commit();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Activated ${selected.length} item(s)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Activate'),
                  ),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final selected = _selectedRows.toSet();
                      if (selected.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No rows selected')),
                        );
                        return;
                      }

                      final imeis = <String>[];
                      for (final doc in _filteredDocs) {
                        if (!selected.contains(doc.id)) continue;
                        final data = doc.data();
                        final imei = '${data['iemi'] ?? ''}'.trim();
                        if (imei.isNotEmpty) imeis.add(imei);
                      }

                      if (imeis.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No IMEI found in selected rows'),
                          ),
                        );
                        return;
                      }

                      await Clipboard.setData(
                        ClipboardData(text: imeis.join(', ')),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied ${imeis.length} IMEI(s) to clipboard',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy IMEI'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('active_iemi')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filtered = docs.where((doc) {
                    final data = doc.data();
                    final isActivated = (data['is_activated'] ?? true) == true;
                    return _showActivatedOnly ? isActivated : !isActivated;
                  }).toList();
                  _filteredDocs = filtered;

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No Records Found'));
                  }

                  final totalRows = filtered.length;
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
                  final pageDocs = filtered.sublist(start, end);

                  final allSelected =
                      filtered.isNotEmpty &&
                      filtered.every((doc) => _selectedRows.contains(doc.id));

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DataTable(
                                  columnSpacing: 24,
                                  columns: [
                                    DataColumn(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: allSelected,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedRows.addAll(
                                                    filtered.map((d) => d.id),
                                                  );
                                                } else {
                                                  for (final d in filtered) {
                                                    _selectedRows.remove(d.id);
                                                  }
                                                }
                                              });
                                            },
                                          ),
                                          const Text('All'),
                                        ],
                                      ),
                                    ),

                                    const DataColumn(label: Text('sl')),

                                    const DataColumn(label: Text('IEMI')),
                                    const DataColumn(
                                      label: Text('Customer name'),
                                    ),
                                    const DataColumn(label: Text('Code')),
                                    const DataColumn(label: Text('Date')),
                                  ],
                                  rows: List.generate(pageDocs.length, (index) {
                                    final doc = pageDocs[index];
                                    final data = doc.data();
                                    final isSelected = _selectedRows.contains(
                                      doc.id,
                                    );
                                    return DataRow(
                                      selected: isSelected,
                                      cells: [
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
                                        DataCell(Text('${start + index + 1}')),

                                        DataCell(Text('${data['iemi'] ?? ''}')),
                                        DataCell(
                                          Text(
                                            '${data['customer_name'] ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${data['customer_code'] ?? ''}',
                                          ),
                                        ),

                                        DataCell(
                                          Text(_formatDate(data['date'])),
                                        ),
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
                                    Text(
                                      'Page ${currentPage + 1} of $totalPages',
                                    ),
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
                                              () => _currentPage =
                                                  currentPage - 1,
                                            ),
                                      icon: const Icon(Icons.navigate_before),
                                    ),
                                    IconButton(
                                      tooltip: 'Next page',
                                      onPressed: currentPage >= totalPages - 1
                                          ? null
                                          : () => setState(
                                              () => _currentPage =
                                                  currentPage + 1,
                                            ),
                                      icon: const Icon(Icons.navigate_next),
                                    ),
                                    IconButton(
                                      tooltip: 'Last page',
                                      onPressed: currentPage >= totalPages - 1
                                          ? null
                                          : () => setState(
                                              () =>
                                                  _currentPage = totalPages - 1,
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
