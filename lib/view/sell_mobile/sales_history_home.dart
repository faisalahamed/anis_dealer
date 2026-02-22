import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalesHistoryHome extends StatefulWidget {
  const SalesHistoryHome({super.key});

  @override
  State<SalesHistoryHome> createState() => _SalesHistoryHomeState();
}

class _SalesHistoryHomeState extends State<SalesHistoryHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';
  int _currentPage = 0;
  int _rowsPerPage = 20;

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('d MMM h:mm a').format(value.toDate().toLocal());
    }
    return '';
  }

  String _formatFilterDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('d MMM yyyy').format(value);
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final imei = '${data['f_iemi'] ?? ''}'.toLowerCase();
    final mobileName = '${data['f_mobile_name'] ?? ''}'.toLowerCase();
    final customerName = '${data['f_customer_name'] ?? ''}'.toLowerCase();

    return imei.contains(query) ||
        mobileName.contains(query) ||
        customerName.contains(query);
  }

  Query<Map<String, dynamic>> _salesQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('sales');

    if (_fromDate != null) {
      final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      query = query.where(
        'selling_date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }

    if (_toDate != null) {
      final toExclusive = DateTime(
        _toDate!.year,
        _toDate!.month,
        _toDate!.day + 1,
      );
      query = query.where(
        'selling_date',
        isLessThan: Timestamp.fromDate(toExclusive),
      );
    }

    return query.orderBy('selling_date', descending: true);
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? _toDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = _fromDate;
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
          _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _showEditSellPriceDialog(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final controller = TextEditingController(
      text: '${data['selling_price'] ?? ''}',
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Selling Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Selling Price'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = num.tryParse(controller.text.trim());
              if (newPrice == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid price')),
                );
                return;
              }

              final buyingPrice = data['f_buying_price'];
              final buy = buyingPrice is num
                  ? buyingPrice
                  : num.tryParse('$buyingPrice') ?? 0;
              final profit = newPrice - buy;

              await _firestore.collection('sales').doc(docId).update({
                'selling_price': newPrice,
                'profit': profit,
                'updated_at': FieldValue.serverTimestamp(),
              });

              final mobileId = '${data['forign_mobile_id'] ?? ''}';
              if (mobileId.isNotEmpty) {
                final receiptQuery = await _firestore
                    .collection('sales_receipts')
                    .where('item_ids', arrayContains: mobileId)
                    .get();

                for (final receiptDoc in receiptQuery.docs) {
                  final receiptData = receiptDoc.data();
                  final itemIdsRaw = receiptData['item_ids'];
                  final pricesRaw = receiptData['item_selling_prices'];

                  if (itemIdsRaw is! List || pricesRaw is! List) {
                    continue;
                  }

                  final itemIds = itemIdsRaw.map((e) => '$e').toList();
                  final prices = pricesRaw
                      .map((e) => e is num ? e : num.tryParse('$e') ?? 0)
                      .toList();

                  final itemIndex = itemIds.indexOf(mobileId);
                  if (itemIndex < 0) {
                    continue;
                  }

                  if (itemIndex >= prices.length) {
                    while (prices.length <= itemIndex) {
                      prices.add(0);
                    }
                  }

                  prices[itemIndex] = newPrice;
                  final totalSelling = prices.fold<num>(
                    0,
                    (sum, val) => sum + (val is num ? val : 0),
                  );
                  final totalBuyingRaw = receiptData['total_buying_cost'];
                  final totalBuying = totalBuyingRaw is num
                      ? totalBuyingRaw
                      : num.tryParse('$totalBuyingRaw') ?? 0;

                  await receiptDoc.reference.update({
                    'item_selling_prices': prices,
                    'total_selling_cost': totalSelling,
                    'total_profit': totalSelling - totalBuying,
                    'updated_at': FieldValue.serverTimestamp(),
                  });
                }
              }

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _printCurrentTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
  ) async {
    final pdf = pw.Document();

    final headers = <String>[
      'Selling Date',
      'Mobile Name',
      'Color',
      'IMEI',
      // 'Buying Price',
      // 'Estimated Price',
      'Selling Price',
      // 'Profit',
      'Customer Name',
      'Customer Mobile',
    ];

    final rows = filteredDocs.map((doc) {
      final data = doc.data();
      return <String>[
        _formatDate(data['selling_date']),
        '${data['f_mobile_name'] ?? ''}',
        '${data['f_color'] ?? ''}',
        '${data['f_iemi'] ?? ''}',
        // '${data['f_buying_price'] ?? ''}',
        // '${data['f_estimated_selling_price'] ?? ''}',
        '${data['selling_price'] ?? ''}',
        // '${data['profit'] ?? ''}',
        '${data['f_customer_name'] ?? ''}',
        '${data['f_customer_mobile'] ?? ''}',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Sales Report',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'From: ${_formatFilterDate(_fromDate).isEmpty ? '-' : _formatFilterDate(_fromDate)}'
            '   To: ${_formatFilterDate(_toDate).isEmpty ? '-' : _formatFilterDate(_toDate)}'
            '   Search: ${_searchQuery.trim().isEmpty ? '-' : _searchQuery.trim()}'
            '   Rows: ${rows.length}',
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
      appBar: AppBar(title: const Text('Sales History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _fromDate == null
                        ? 'From Date'
                        : 'From: ${_formatFilterDate(_fromDate)}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickToDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _toDate == null
                        ? 'To Date'
                        : 'To: ${_formatFilterDate(_toDate)}',
                  ),
                ),
                if (_fromDate != null || _toDate != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search IMEI / Mobile / Customer',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
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
              ],
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AppScrollBehavior(),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _salesQuery().snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Sales Found'));
                  }

                  final docs = snapshot.data!.docs
                      .where((doc) => _matchesSearch(doc.data()))
                      .toList();
                  if (docs.isEmpty) {
                    return const Center(child: Text('No Matching Sales Found'));
                  }
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
                                columns: const [
                                  DataColumn(label: Text('Selling Date')),
                                  // DataColumn(label: Text('Mobile ID')),
                                  DataColumn(label: Text('Mobile Name')),
                                  DataColumn(label: Text('Color')),
                                  DataColumn(label: Text('IMEI')),
                                  DataColumn(label: Text('Buying Price')),
                                  DataColumn(label: Text('Estimated Price')),
                                  DataColumn(label: Text('Selling Price')),
                                  DataColumn(label: Text('Profit')),
                                  // DataColumn(label: Text('Customer ID')),
                                  DataColumn(label: Text('Customer Name')),
                                  DataColumn(label: Text('Customer Mobile')),
                                  DataColumn(label: Text('Edit')),
                                ],
                                rows: pageDocs.map((doc) {
                                  final data = doc.data();
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(_formatDate(data['selling_date'])),
                                      ),
                                      // DataCell(
                                      //   Text('${data['forign_mobile_id'] ?? ''}'),
                                      // ),
                                      DataCell(
                                        Text('${data['f_mobile_name'] ?? ''}'),
                                      ),
                                      DataCell(
                                        Text('${data['f_color'] ?? ''}'),
                                      ),
                                      DataCell(Text('${data['f_iemi'] ?? ''}')),
                                      DataCell(
                                        Text('${data['f_buying_price'] ?? ''}'),
                                      ),
                                      DataCell(
                                        Text(
                                          '${data['f_estimated_selling_price'] ?? ''}',
                                        ),
                                      ),
                                      DataCell(
                                        Text('${data['selling_price'] ?? ''}'),
                                      ),
                                      DataCell(Text('${data['profit'] ?? ''}')),
                                      // DataCell(
                                      //   Text('${data['f_customer_id'] ?? ''}'),
                                      // ),
                                      DataCell(
                                        Text(
                                          '${data['f_customer_name'] ?? ''}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${data['f_customer_mobile'] ?? ''}',
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              _showEditSellPriceDialog(
                                                doc.id,
                                                data,
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _printCurrentTable(docs),
                                    icon: const Icon(Icons.print),
                                    label: const Text('Print Table'),
                                  ),
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
                                        value: 100,
                                        child: Text('100'),
                                      ),
                                      DropdownMenuItem(
                                        value: 500,
                                        child: Text('500'),
                                      ),
                                      DropdownMenuItem(
                                        value: 1000,
                                        child: Text('1000'),
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
                                        : () =>
                                              setState(() => _currentPage = 0),
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
                                    onPressed: currentPage >= totalPages - 1
                                        ? null
                                        : () => setState(
                                            () =>
                                                _currentPage = currentPage + 1,
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
