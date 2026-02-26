import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerBillDetails extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerMobile;

  const CustomerBillDetails({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
  });

  @override
  State<CustomerBillDetails> createState() => _CustomerBillDetailsState();
}

class _CustomerBillDetailsState extends State<CustomerBillDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();
  final ScrollController _cashHController = ScrollController();
  final ScrollController _cashVController = ScrollController();
  DateTime? _billFromDate;
  DateTime? _billToDate;
  DateTime? _cashFromDate;
  DateTime? _cashToDate;
  int _billCurrentPage = 0;
  int _billRowsPerPage = 5;
  int _cashCurrentPage = 0;
  int _cashRowsPerPage = 5;

  void _showReceiveCashDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive Cash'),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
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
              final amount = num.tryParse(amountController.text.trim());
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid amount')),
                );
                return;
              }

              await _firestore.collection('cash_received').add({
                'customer_id': widget.customerId,
                'customer_name': widget.customerName,
                'customer_mobile': widget.customerMobile,
                'amount': amount,
                'note': noteController.text.trim(),
                'created_at': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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

  bool _isWithinSelectedRange(
    dynamic value,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (fromDate == null && toDate == null) return true;
    if (value is! Timestamp) return false;

    final dt = value.toDate().toLocal();
    final day = DateTime(dt.year, dt.month, dt.day);
    if (fromDate != null) {
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      if (day.isBefore(from)) return false;
    }
    if (toDate != null) {
      final to = DateTime(toDate.year, toDate.month, toDate.day);
      if (day.isAfter(to)) return false;
    }
    return true;
  }

  Future<void> _pickBillFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _billFromDate ?? _billToDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _billFromDate = picked;
        if (_billToDate != null && _billToDate!.isBefore(_billFromDate!)) {
          _billToDate = _billFromDate;
        }
      });
    }
  }

  Future<void> _pickBillToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _billToDate ?? _billFromDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _billToDate = picked;
        if (_billFromDate != null && _billToDate!.isBefore(_billFromDate!)) {
          _billFromDate = _billToDate;
        }
      });
    }
  }

  Future<void> _pickCashFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _cashFromDate ?? _cashToDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _cashFromDate = picked;
        if (_cashToDate != null && _cashToDate!.isBefore(_cashFromDate!)) {
          _cashToDate = _cashFromDate;
        }
      });
    }
  }

  Future<void> _pickCashToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _cashToDate ?? _cashFromDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _cashToDate = picked;
        if (_cashFromDate != null && _cashToDate!.isBefore(_cashFromDate!)) {
          _cashFromDate = _cashToDate;
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

  Widget _ellipsisCell(String text, {double maxWidth = 260}) {
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

  Future<void> _printBillsTable(
    List<QueryDocumentSnapshot> docs, {
    required num totalBuying,
    required num totalEstimated,
    required num totalSelling,
    required num totalProfit,
  }) async {
    final pdf = pw.Document();

    final rows = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return <String>[
        _formatDate(data['created_at']),
        '${data['item_names'] ?? ''}',
        _formatImeis(data['imeis']),
        '${data['item_count'] ?? ''}',
        // '${data['total_buying_cost'] ?? ''}',
        // '${data['total_estimated_cost'] ?? ''}',
        '${data['total_selling_cost'] ?? ''}',
        // '${data['total_profit'] ?? ''}',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Customer Bills - ${widget.customerName}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Mobile: ${widget.customerMobile}'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Item Names',
              'IMEIs',
              'Count',
              // 'Total Buying',
              // 'Total Estimated',
              'Total Bill',
              // 'Total Profit',
            ],
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              4: const pw.FixedColumnWidth(170),
              3: const pw.FixedColumnWidth(120),
            },
          ),
          pw.SizedBox(height: 10),
          // pw.Text(
          //   'Totals -> Buying: $totalBuying, Estimated: $totalEstimated, Selling: $totalSelling, Profit: $totalProfit',
          // ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _printCashTable(
    List<QueryDocumentSnapshot> cashDocs, {
    required num totalCash,
    required num balanceDue,
  }) async {
    final pdf = pw.Document();

    final rows = cashDocs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return <String>[
        _formatDate(data['created_at']),
        '${data['amount'] ?? ''}',
        '${data['note'] ?? ''}',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Cash Received - ${widget.customerName}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Mobile: ${widget.customerMobile}'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Amount', 'Note'],
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Totals -> Cash: $totalCash, Balance Due: $balanceDue'),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _showEditCashDialog(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final amountController = TextEditingController(text: '${data['amount'] ?? ''}');
    final noteController = TextEditingController(text: '${data['note'] ?? ''}');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cash Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
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
              final amount = num.tryParse(amountController.text.trim());
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid amount')),
                );
                return;
              }

              await _firestore.collection('cash_received').doc(docId).update({
                'amount': amount,
                'note': noteController.text.trim(),
                'updated_at': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCashRecord(String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cash Record'),
        content: const Text('Do you want to delete this record?'),
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
      await _firestore.collection('cash_received').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bills: ${widget.customerName}'),
            Text(
              widget.customerMobile,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [],
      ),
      body: ScrollConfiguration(
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

            if (!snapshot.hasData) {
              return const Center(child: Text('No Bills Found'));
            }

            final allDocs = snapshot.data!.docs;
            final docs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['customer_id'] ?? '').toString() ==
                      widget.customerId &&
                  _isWithinSelectedRange(
                    data['created_at'],
                    _billFromDate,
                    _billToDate,
                  );
            }).toList();
            final billTotalRows = docs.length;
            final billTotalPages = billTotalRows == 0
                ? 1
                : ((billTotalRows + _billRowsPerPage - 1) ~/ _billRowsPerPage);
            final billPage = _billCurrentPage >= billTotalPages
                ? billTotalPages - 1
                : _billCurrentPage;
            final billStart = billPage * _billRowsPerPage;
            final billEnd = (billStart + _billRowsPerPage) > billTotalRows
                ? billTotalRows
                : (billStart + _billRowsPerPage);
            final billPageDocs = docs.sublist(billStart, billEnd);

            num totalBuying = 0;
            num totalEstimated = 0;
            num totalSelling = 0;
            num totalProfit = 0;

            num _toNum(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalBuying += _toNum(data['total_buying_cost']);
              totalEstimated += _toNum(data['total_estimated_cost']);
              totalSelling += _toNum(data['total_selling_cost']);
              totalProfit += _toNum(data['total_profit']);
            }

            return Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickBillFromDate,
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                _billFromDate == null
                                    ? 'From Date'
                                    : 'From: ${_formatFilterDate(_billFromDate)}',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickBillToDate,
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                _billToDate == null
                                    ? 'To Date'
                                    : 'To: ${_formatFilterDate(_billToDate)}',
                              ),
                            ),
                            if (_billFromDate != null || _billToDate != null)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _billFromDate = null;
                                    _billToDate = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear'),
                              ),

                            ElevatedButton.icon(
                              onPressed: () => _printBillsTable(
                                docs,
                                totalBuying: totalBuying,
                                totalEstimated: totalEstimated,
                                totalSelling: totalSelling,
                                totalProfit: totalProfit,
                              ),
                              icon: const Icon(Icons.print),
                              label: const Text('Print Bills'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: DataTable(
                                    dataRowMinHeight: 48,
                                    dataRowMaxHeight: 64,
                                    columns: const [
                                      // DataColumn(label: Text('Receipt ID')),
                                      DataColumn(label: Text('Date')),
                                      DataColumn(label: Text('Item Names')),
                                      DataColumn(label: Text('IMEIs')),
                                      DataColumn(label: Text('Item Count')),
                                      DataColumn(label: Text('Total Buying')),
                                      DataColumn(
                                        label: Text('Total Estimated'),
                                      ),
                                      DataColumn(label: Text('Total Selling')),
                                      DataColumn(label: Text('Total Profit')),
                                    ],
                                    rows: billPageDocs.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      return DataRow(
                                        cells: [
                                          // DataCell(
                                          //   Text('${data['receipt_id'] ?? doc.id}'),
                                          // ),
                                          DataCell(
                                            Text(
                                              _formatDate(data['created_at']),
                                            ),
                                          ),
                                          DataCell(
                                            _ellipsisCell(
                                              '${data['item_names'] ?? ''}',
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
                                            Text(
                                              '${data['total_profit'] ?? ''}',
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Rows per page:'),
                          DropdownButton<int>(
                            value: _billRowsPerPage,
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5')),
                              DropdownMenuItem(value: 10, child: Text('10')),
                              DropdownMenuItem(value: 50, child: Text('50')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _billRowsPerPage = value;
                                _billCurrentPage = 0;
                              });
                            },
                          ),
                          Text('Page ${billPage + 1} of $billTotalPages'),
                          IconButton(
                            tooltip: 'First page',
                            onPressed: billPage == 0
                                ? null
                                : () => setState(() => _billCurrentPage = 0),
                            icon: const Icon(Icons.first_page),
                          ),
                          IconButton(
                            tooltip: 'Previous page',
                            onPressed: billPage == 0
                                ? null
                                : () => setState(
                                    () => _billCurrentPage = billPage - 1,
                                  ),
                            icon: const Icon(Icons.navigate_before),
                          ),
                          IconButton(
                            tooltip: 'Next page',
                            onPressed: billPage >= billTotalPages - 1
                                ? null
                                : () => setState(
                                    () => _billCurrentPage = billPage + 1,
                                  ),
                            icon: const Icon(Icons.navigate_next),
                          ),
                          IconButton(
                            tooltip: 'Last page',
                            onPressed: billPage >= billTotalPages - 1
                                ? null
                                : () => setState(
                                    () => _billCurrentPage = billTotalPages - 1,
                                  ),
                            icon: const Icon(Icons.last_page),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          border: const Border(
                            top: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 8,
                          children: [
                            Text('Total Buying: $totalBuying'),
                            Text('Total Estimated: $totalEstimated'),
                            Text('Total Selling: $totalSelling'),
                            Text('Total Profit: $totalProfit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Cash Received',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FilledButton.icon(
                                onPressed: _showReceiveCashDialog,
                                icon: const Icon(Icons.payments),
                                label: const Text('Receive Cash'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('cash_received')
                              .orderBy('created_at', descending: true)
                              .snapshots(),
                          builder: (context, cashSnap) {
                            if (cashSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!cashSnap.hasData) {
                              return const Center(
                                child: Text('No Cash Records'),
                              );
                            }

                            final allCash = cashSnap.data!.docs;
                            final cashDocs = allCash.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return (data['customer_id'] ?? '').toString() ==
                                      widget.customerId &&
                                  _isWithinSelectedRange(
                                    data['created_at'],
                                    _cashFromDate,
                                    _cashToDate,
                                  );
                            }).toList();
                            final cashTotalRows = cashDocs.length;
                            final cashTotalPages = cashTotalRows == 0
                                ? 1
                                : ((cashTotalRows + _cashRowsPerPage - 1) ~/
                                      _cashRowsPerPage);
                            final cashPage = _cashCurrentPage >= cashTotalPages
                                ? cashTotalPages - 1
                                : _cashCurrentPage;
                            final cashStart = cashPage * _cashRowsPerPage;
                            final cashEnd =
                                (cashStart + _cashRowsPerPage) > cashTotalRows
                                ? cashTotalRows
                                : (cashStart + _cashRowsPerPage);
                            final cashPageDocs = cashDocs.sublist(
                              cashStart,
                              cashEnd,
                            );

                            if (cashDocs.isEmpty) {
                              return const Center(
                                child: Text('No Cash Records'),
                              );
                            }

                            num totalCash = 0;
                            for (final doc in cashDocs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final amount = data['amount'];
                              if (amount is num) {
                                totalCash += amount;
                              } else {
                                totalCash += num.tryParse('$amount') ?? 0;
                              }
                            }

                            return Column(
                              children: [
                                Expanded(
                                  child: Scrollbar(
                                    controller: _cashVController,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _cashVController,
                                      scrollDirection: Axis.vertical,
                                      child: Scrollbar(
                                        controller: _cashHController,
                                        thumbVisibility: true,
                                        notificationPredicate: (notification) =>
                                            notification.metrics.axis ==
                                            Axis.horizontal,
                                        child: SingleChildScrollView(
                                          controller: _cashHController,
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            dataRowMinHeight: 44,
                                            dataRowMaxHeight: 56,
                                            columns: const [
                                              DataColumn(label: Text('Date')),
                                              DataColumn(label: Text('Amount')),
                                              DataColumn(label: Text('Note')),
                                              DataColumn(label: Text('Actions')),
                                            ],
                                            rows: cashPageDocs.map((doc) {
                                              final data =
                                                  doc.data()
                                                      as Map<String, dynamic>;
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      _formatDate(
                                                        data['created_at'],
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      '${data['amount'] ?? ''}',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    _ellipsisCell(
                                                      '${data['note'] ?? ''}',
                                                      maxWidth: 300,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          tooltip: 'Edit',
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            size: 18,
                                                          ),
                                                          onPressed: () =>
                                                              _showEditCashDialog(
                                                                doc.id,
                                                                data,
                                                              ),
                                                        ),
                                                        IconButton(
                                                          tooltip: 'Delete',
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            size: 18,
                                                          ),
                                                          onPressed: () =>
                                                              _deleteCashRecord(
                                                                doc.id,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text('Rows per page:'),
                                    DropdownButton<int>(
                                      value: _cashRowsPerPage,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 5,
                                          child: Text('5'),
                                        ),
                                        DropdownMenuItem(
                                          value: 10,
                                          child: Text('10'),
                                        ),
                                        DropdownMenuItem(
                                          value: 50,
                                          child: Text('50'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _cashRowsPerPage = value;
                                          _cashCurrentPage = 0;
                                        });
                                      },
                                    ),
                                    Text(
                                      'Page ${cashPage + 1} of $cashTotalPages',
                                    ),
                                    IconButton(
                                      tooltip: 'First page',
                                      onPressed: cashPage == 0
                                          ? null
                                          : () => setState(
                                              () => _cashCurrentPage = 0,
                                            ),
                                      icon: const Icon(Icons.first_page),
                                    ),
                                    IconButton(
                                      tooltip: 'Previous page',
                                      onPressed: cashPage == 0
                                          ? null
                                          : () => setState(
                                              () => _cashCurrentPage =
                                                  cashPage - 1,
                                            ),
                                      icon: const Icon(Icons.navigate_before),
                                    ),
                                    IconButton(
                                      tooltip: 'Next page',
                                      onPressed: cashPage >= cashTotalPages - 1
                                          ? null
                                          : () => setState(
                                              () => _cashCurrentPage =
                                                  cashPage + 1,
                                            ),
                                      icon: const Icon(Icons.navigate_next),
                                    ),
                                    IconButton(
                                      tooltip: 'Last page',
                                      onPressed: cashPage >= cashTotalPages - 1
                                          ? null
                                          : () => setState(
                                              () => _cashCurrentPage =
                                                  cashTotalPages - 1,
                                            ),
                                      icon: const Icon(Icons.last_page),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                    border: const Border(
                                      top: BorderSide(color: Colors.black12),
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 24,
                                    runSpacing: 8,
                                    children: [
                                      Text('Total Cash: $totalCash'),
                                      Text(
                                        'Balance Due: ${totalSelling - totalCash}',
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _pickCashFromDate,
                                        icon: const Icon(Icons.date_range),
                                        label: Text(
                                          _cashFromDate == null
                                              ? 'From Date'
                                              : 'From: ${_formatFilterDate(_cashFromDate)}',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _pickCashToDate,
                                        icon: const Icon(Icons.date_range),
                                        label: Text(
                                          _cashToDate == null
                                              ? 'To Date'
                                              : 'To: ${_formatFilterDate(_cashToDate)}',
                                        ),
                                      ),
                                      if (_cashFromDate != null ||
                                          _cashToDate != null)
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _cashFromDate = null;
                                              _cashToDate = null;
                                            });
                                          },
                                          icon: const Icon(Icons.clear),
                                          label: const Text('Clear'),
                                        ),

                                      ElevatedButton.icon(
                                        onPressed: () => _printCashTable(
                                          cashDocs,
                                          totalCash: totalCash,
                                          balanceDue: totalSelling - totalCash,
                                        ),
                                        icon: const Icon(Icons.print),
                                        label: const Text('Print Cash'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
