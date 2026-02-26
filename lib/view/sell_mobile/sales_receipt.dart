import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalesReceiptHome extends StatefulWidget {
  const SalesReceiptHome({super.key});

  @override
  State<SalesReceiptHome> createState() => _SalesReceiptHomeState();
}

class _SalesReceiptHomeState extends State<SalesReceiptHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();
  DateTime? _fromDate;
  DateTime? _toDate;

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

  bool _isWithinSelectedRange(dynamic value) {
    if (_fromDate == null && _toDate == null) return true;
    if (value is! Timestamp) return false;

    final dt = value.toDate().toLocal();
    final day = DateTime(dt.year, dt.month, dt.day);
    if (_fromDate != null) {
      final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      if (day.isBefore(from)) return false;
    }
    if (_toDate != null) {
      final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
      if (day.isAfter(to)) return false;
    }
    return true;
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

  String _formatImeis(dynamic value) {
    if (value is Iterable) {
      return value.map((e) => e.toString()).join(', ');
    }
    if (value == null) return '';
    return value.toString();
  }

  String _formatItemNamesWithPrices(Map<String, dynamic> data) {
    final namesRaw = data['item_names_list'];
    final pricesRaw = data['item_selling_prices'];

    final names = <String>[];
    if (namesRaw is Iterable) {
      names.addAll(namesRaw.map((e) => e.toString()));
    } else {
      final fallback = (data['item_names'] ?? '').toString();
      if (fallback.isNotEmpty) {
        names.addAll(fallback.split(', ').map((e) => e.trim()));
      }
    }

    final prices = <String>[];
    if (pricesRaw is Iterable) {
      prices.addAll(pricesRaw.map((e) => e.toString()));
    }

    if (prices.isNotEmpty && prices.length == names.length) {
      return List.generate(
        names.length,
        (i) => '${names[i]} (${prices[i]})',
      ).join(', ');
    }

    return names.join(', ');
  }

  Future<void> _printReceipt(Map<String, dynamic> data) async {
    final doc = pw.Document();

    final itemNames = _formatItemNamesWithPrices(data);
    final imeis = _formatImeis(data['imeis']);
    final dateText = _formatDate(data['created_at']);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Anis Mobile Dealer',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Receipt ID: ${data['receipt_id'] ?? ''}'),
              pw.Text('Date: $dateText'),
              pw.Divider(),
              pw.Text(
                'Customer',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Name: ${data['customer_name'] ?? ''}'),
              pw.Text('Mobile: ${data['customer_mobile'] ?? ''}'),
              pw.Text('Address: ${data['customer_address'] ?? ''}'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Items',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(itemNames),
              pw.SizedBox(height: 12),
              pw.Text('IMEIs: $imeis'),
              pw.SizedBox(height: 12),
              pw.Text('Count: ${data['item_count'] ?? ''}'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Totals',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Total Selling Bill: ${data['total_selling_cost'] ?? ''}',
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> _printReceiptsRange(List<QueryDocumentSnapshot> docs) async {
    final doc = pw.Document();
    final rows = docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return <String>[
        _formatDate(data['created_at']),
        '${data['customer_name'] ?? ''}',
        _formatItemNamesWithPrices(data),
        _formatImeis(data['imeis']),
        '${data['item_count'] ?? ''}',
        '${data['total_selling_cost'] ?? ''}',
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Text(
            'Sales Receipts Report',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'From: ${_formatFilterDate(_fromDate).isEmpty ? '-' : _formatFilterDate(_fromDate)}'
            '   To: ${_formatFilterDate(_toDate).isEmpty ? '-' : _formatFilterDate(_toDate)}'
            '   Rows: ${rows.length}',
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Customer',
              'Item Names',
              'IMEIs',
              'Count',
              'Total Selling',
            ],
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              1: const pw.FixedColumnWidth(100),
              2: const pw.FixedColumnWidth(130),
              4: const pw.FixedColumnWidth(100),
              5: const pw.FixedColumnWidth(130),
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Widget _ellipsisCell(String text, {double maxWidth = 240}) {
    return Tooltip(
      message: text,
      child: SizedBox(
        width: maxWidth,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
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
      appBar: AppBar(title: const Text('Sales Receipts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
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
              ],
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AppScrollBehavior(),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('sales_receipts')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Receipts Found'));
                  }

                  final docs = snapshot.data!.docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return _isWithinSelectedRange(data['created_at']);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No Receipts Found'));
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
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _printReceiptsRange(docs),
                                  icon: const Icon(Icons.print),
                                  label: const Text('Print Range'),
                                ),
                                const SizedBox(height: 8),
                                DataTable(
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 64,
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Customer Name')),
                                    DataColumn(label: Text('Item Names')),
                                    DataColumn(label: Text('IMEI Numbers')),
                                    DataColumn(label: Text('Item Count')),
                                    DataColumn(label: Text('Total Buying')),
                                    DataColumn(label: Text('Total Estimated')),
                                    DataColumn(label: Text('Total Selling')),
                                    DataColumn(label: Text('Total Profit')),
                                    DataColumn(label: Text('Print')),
                                  ],
                                  rows: docs.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(_formatDate(data['created_at'])),
                                        ),
                                        DataCell(
                                          Text(
                                            '${data['customer_name'] ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          _ellipsisCell(
                                            _formatItemNamesWithPrices(data),
                                          ),
                                        ),
                                        DataCell(
                                          _ellipsisCell(
                                            _formatImeis(data['imeis']),
                                          ),
                                        ),
                                        DataCell(
                                          Text('${data['item_count'] ?? ''}'),
                                        ),
                                        DataCell(
                                          Text(
                                            '${data['total_buying_cost'] ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${data['total_estimated_cost'] ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${data['total_selling_cost'] ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          Text('${data['total_profit'] ?? ''}'),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.print,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _printReceipt(data),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
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
