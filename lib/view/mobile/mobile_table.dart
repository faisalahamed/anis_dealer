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
  int? _sortColumnIndex = 6;
  bool _sortAscending = false;
  String _sortField = 'createdAt';
  int _currentPage = 0;
  int _rowsPerPage = 20;

  String _formatDate(DateTime date) {
    return DateFormat('d MMM h:mm a').format(date);
  }

  String _createdAtToString(dynamic value) {
    if (value is Timestamp) {
      return _formatDate(value.toDate().toLocal());
    }
    return '';
  }

  int _compareDocs(
    QueryDocumentSnapshot a,
    QueryDocumentSnapshot b,
    String field,
    bool ascending,
  ) {
    final aData = a.data() as Map<String, dynamic>;
    final bData = b.data() as Map<String, dynamic>;
    int result;

    switch (field) {
      case 'iemi':
      case 'buyPrice':
      case 'estimatedSellingPrice':
        final aVal = int.tryParse('${aData[field] ?? 0}') ?? 0;
        final bVal = int.tryParse('${bData[field] ?? 0}') ?? 0;
        result = aVal.compareTo(bVal);
        break;
      case 'isSold':
        final aVal = (aData['isSold'] ?? false) == true ? 1 : 0;
        final bVal = (bData['isSold'] ?? false) == true ? 1 : 0;
        result = aVal.compareTo(bVal);
        break;
      case 'createdAt':
        final aTs = aData['createdAt'];
        final bTs = bData['createdAt'];
        final aDate = aTs is Timestamp ? aTs.toDate() : DateTime(1970);
        final bDate = bTs is Timestamp ? bTs.toDate() : DateTime(1970);
        result = aDate.compareTo(bDate);
        break;
      default:
        final aVal = (aData[field] ?? '').toString().toLowerCase();
        final bVal = (bData[field] ?? '').toString().toLowerCase();
        result = aVal.compareTo(bVal);
    }

    return ascending ? result : -result;
  }

  void _onSort(int columnIndex, String field, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortField = field;
      _sortAscending = ascending;
      _currentPage = 0;
    });
  }

  void _showEditMobileDialog(String docId, Map<String, dynamic> data) {
    final imeiController = TextEditingController(text: '${data['iemi'] ?? ''}');
    final nameController = TextEditingController(text: '${data['name'] ?? ''}');
    final colorController = TextEditingController(
      text: '${data['color'] ?? ''}',
    );
    final buyPriceController = TextEditingController(
      text: '${data['buyPrice'] ?? ''}',
    );
    final estSellPriceController = TextEditingController(
      text: '${data['estimatedSellingPrice'] ?? ''}',
    );
    final descriptionController = TextEditingController(
      text: '${data['description'] ?? ''}',
    );
    bool isSold = (data['isSold'] ?? false) == true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Edit Mobile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: imeiController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'IMEI'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Mobile Name'),
                ),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color'),
                ),
                TextField(
                  controller: buyPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Buy Price'),
                ),
                TextField(
                  controller: estSellPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Est. Sell Price',
                  ),
                ),
                // DropdownButtonFormField<bool>(
                //   initialValue: isSold,
                //   decoration: const InputDecoration(labelText: 'Sold'),
                //   items: const [
                //     DropdownMenuItem(value: false, child: Text('No')),
                //     DropdownMenuItem(value: true, child: Text('Yes')),
                //   ],
                //   onChanged: (value) {
                //     setLocalState(() {
                //       isSold = value ?? false;
                //     });
                //   },
                // ),
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
                final buyPrice = int.tryParse(buyPriceController.text.trim());
                final estSellPrice = int.tryParse(
                  estSellPriceController.text.trim(),
                );

                if (nameController.text.trim().isEmpty ||
                    colorController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    buyPrice == null ||
                    estSellPrice == null) {
                  return;
                }

                await _firestore.collection('mobiles').doc(docId).update({
                  'name': nameController.text.trim(),
                  'color': colorController.text.trim(),
                  'buyPrice': buyPrice,
                  'estimatedSellingPrice': estSellPrice,
                  'isSold': isSold,
                  'description': descriptionController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMobile(String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mobile'),
        content: const Text('Do you want to delete this mobile?'),
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
      await _firestore.collection('mobiles').doc(docId).delete();
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
      appBar: AppBar(title: Text('Add Mobiles')),
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

                  final docs = List<QueryDocumentSnapshot>.from(
                    snapshot.data!.docs,
                  )..sort(
                      (a, b) => _compareDocs(a, b, _sortField, _sortAscending),
                    );
                  final totalRows = docs.length;
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
                  final pageDocs = docs.sublist(start, end);

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
                                  // DataColumn(label: Text('Mobile ID')),
                                  DataColumn(
                                    label: const Text('IEMI'),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) =>
                                        _onSort(columnIndex, 'iemi', ascending),
                                  ),
                                  // DataColumn(label: Text('Model ID')),
                                  DataColumn(
                                    label: const Text('Mobile Name'),
                                    onSort: (columnIndex, ascending) => _onSort(
                                      columnIndex,
                                      'name',
                                      ascending,
                                    ),
                                  ),
                                  DataColumn(
                                    label: const Text('Color'),
                                    onSort: (columnIndex, ascending) => _onSort(
                                      columnIndex,
                                      'color',
                                      ascending,
                                    ),
                                  ),
                                  DataColumn(
                                    label: const Text('Buy Price'),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) => _onSort(
                                      columnIndex,
                                      'buyPrice',
                                      ascending,
                                    ),
                                  ),
                                  DataColumn(
                                    label: const Text('Est. Sell Price'),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) => _onSort(
                                      columnIndex,
                                      'estimatedSellingPrice',
                                      ascending,
                                    ),
                                  ),
                                  DataColumn(
                                    label: const Text('Sold'),
                                    onSort: (columnIndex, ascending) => _onSort(
                                      columnIndex,
                                      'isSold',
                                      ascending,
                                    ),
                                  ),
                                  DataColumn(
                                    label: const Text('Date'),
                                    onSort: (columnIndex, ascending) => _onSort(
                                      columnIndex,
                                      'createdAt',
                                      ascending,
                                    ),
                                  ),
                                  DataColumn(
                                    label: const Text('Description'),
                                    onSort: (columnIndex, ascending) => _onSort(
                                      columnIndex,
                                      'description',
                                      ascending,
                                    ),
                                  ),
                                  const DataColumn(label: Text('Actions')),
                                ],
                                rows: pageDocs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  return DataRow(
                                    cells: [
                                      // DataCell(Text(doc.id)),
                                      DataCell(Text('${data['iemi'] ?? ''}')),
                                      // DataCell(Text('${data['modelId'] ?? ''}')),
                                      DataCell(Text('${data['name'] ?? ''}')),
                                      DataCell(Text('${data['color'] ?? ''}')),
                                      DataCell(
                                        Text('${data['buyPrice'] ?? ''}'),
                                      ),
                                      DataCell(
                                        Text(
                                          '${data['estimatedSellingPrice'] ?? ''}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          (data['isSold'] ?? false)
                                              ? 'Yes'
                                              : 'No',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _createdAtToString(data['createdAt']),
                                        ),
                                      ),
                                      DataCell(
                                        Text('${data['description'] ?? ''}'),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Edit',
                                              icon: const Icon(Icons.edit),
                                              onPressed: () =>
                                                  _showEditMobileDialog(
                                                    doc.id,
                                                    data,
                                                  ),
                                            ),
                                            IconButton(
                                              tooltip: 'Delete',
                                              icon: const Icon(Icons.delete),
                                              onPressed: () =>
                                                  _deleteMobile(doc.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Rows per page:'),
                                  const SizedBox(width: 8),
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
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _rowsPerPage = value;
                                        _currentPage = 0;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  Text('Page ${currentPage + 1} of $totalPages'),
                                  IconButton(
                                    tooltip: 'First page',
                                    onPressed: currentPage == 0
                                        ? null
                                        : () => setState(() => _currentPage = 0),
                                    icon: const Icon(Icons.first_page),
                                  ),
                                  IconButton(
                                    tooltip: 'Previous page',
                                    onPressed: currentPage == 0
                                        ? null
                                        : () => setState(
                                            () => _currentPage = currentPage - 1,
                                          ),
                                    icon: const Icon(Icons.navigate_before),
                                  ),
                                  IconButton(
                                    tooltip: 'Next page',
                                    onPressed: currentPage >= totalPages - 1
                                        ? null
                                        : () => setState(
                                            () => _currentPage = currentPage + 1,
                                          ),
                                    icon: const Icon(Icons.navigate_next),
                                  ),
                                  IconButton(
                                    tooltip: 'Last page',
                                    onPressed: currentPage >= totalPages - 1
                                        ? null
                                        : () => setState(
                                            () => _currentPage = totalPages - 1,
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
