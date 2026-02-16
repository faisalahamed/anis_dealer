import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';

class SalesHistoryHome extends StatefulWidget {
  const SalesHistoryHome({super.key});

  @override
  State<SalesHistoryHome> createState() => _SalesHistoryHomeState();
}

class _SalesHistoryHomeState extends State<SalesHistoryHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('d MMM h:mm a').format(value.toDate().toLocal());
    }
    return '';
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

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: ScrollConfiguration(
        behavior: const _AppScrollBehavior(),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('sales')
              .orderBy('selling_date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No Sales Found'));
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
                      columns: const [
                        // DataColumn(label: Text('Selling ID')),
                        DataColumn(label: Text('Selling Date')),
                        DataColumn(label: Text('Mobile ID')),
                        DataColumn(label: Text('Mobile Name')),
                        DataColumn(label: Text('Color')),
                        DataColumn(label: Text('IMEI')),
                        DataColumn(label: Text('Buying Price')),
                        DataColumn(label: Text('Estimated Price')),
                        DataColumn(label: Text('Selling Price')),
                        DataColumn(label: Text('Profit')),
                        DataColumn(label: Text('Customer ID')),
                        DataColumn(label: Text('Customer Name')),
                        DataColumn(label: Text('Customer Mobile')),
                        DataColumn(label: Text('Edit')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            // DataCell(Text('${data['selling_id'] ?? doc.id}')),
                            DataCell(Text(_formatDate(data['selling_date']))),
                            DataCell(Text('${data['forign_mobile_id'] ?? ''}')),
                            DataCell(Text('${data['f_mobile_name'] ?? ''}')),
                            DataCell(Text('${data['f_color'] ?? ''}')),
                            DataCell(Text('${data['f_iemi'] ?? ''}')),
                            DataCell(Text('${data['f_buying_price'] ?? ''}')),
                            DataCell(
                              Text(
                                '${data['f_estimated_selling_price'] ?? ''}',
                              ),
                            ),
                            DataCell(Text('${data['selling_price'] ?? ''}')),
                            DataCell(Text('${data['profit'] ?? ''}')),
                            DataCell(Text('${data['f_customer_id'] ?? ''}')),
                            DataCell(Text('${data['f_customer_name'] ?? ''}')),
                            DataCell(
                              Text('${data['f_customer_mobile'] ?? ''}'),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () =>
                                    _showEditSellPriceDialog(doc.id, data),
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
