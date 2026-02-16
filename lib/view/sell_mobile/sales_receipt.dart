import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
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

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('d MMM h:mm a').format(value.toDate().toLocal());
    }
    return '';
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
              // pw.Text('Total Buying: ${data['total_buying_cost'] ?? ''}'),
              // pw.Text('Total Estimated: ${data['total_estimated_cost'] ?? ''}'),
              pw.Text(
                'Total Selling Bill: ${data['total_selling_cost'] ?? ''}',
              ),
              // pw.Text('Total Profit: ${data['total_profit'] ?? ''}'),
            ],
          );
        },
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Receipts')),
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

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No Receipts Found'));
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
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 64,
                      columns: const [
                        // DataColumn(label: Text('Receipt ID')),
                        DataColumn(label: Text('Date')),
                        // DataColumn(label: Text('Customer ID')),
                        DataColumn(label: Text('Customer Name')),
                        DataColumn(label: Text('Customer Mobile')),
                        // DataColumn(label: Text('Customer Address')),
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
                        final data = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            // DataCell(Text('${data['receipt_id'] ?? doc.id}')),
                            DataCell(Text(_formatDate(data['created_at']))),
                            // DataCell(Text('${data['customer_id'] ?? ''}')),
                            DataCell(Text('${data['customer_name'] ?? ''}')),
                            DataCell(Text('${data['customer_mobile'] ?? ''}')),
                            // DataCell(Text('${data['customer_address'] ?? ''}')),
                            DataCell(
                              _ellipsisCell(_formatItemNamesWithPrices(data)),
                            ),
                            DataCell(
                              _ellipsisCell(_formatImeis(data['imeis'])),
                            ),
                            DataCell(Text('${data['item_count'] ?? ''}')),
                            DataCell(
                              Text('${data['total_buying_cost'] ?? ''}'),
                            ),
                            DataCell(
                              Text('${data['total_estimated_cost'] ?? ''}'),
                            ),
                            DataCell(
                              Text('${data['total_selling_cost'] ?? ''}'),
                            ),
                            DataCell(Text('${data['total_profit'] ?? ''}')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.print, size: 18),
                                onPressed: () => _printReceipt(data),
                              ),
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
