import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

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
        actions: [
          Container(
            color: Colors.green,
            child: TextButton.icon(
              onPressed: _showReceiveCashDialog,
              icon: const Icon(Icons.payments, color: Colors.yellowAccent),
              label: const Text(
                'Receive Cash',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ),
        ],
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
                  widget.customerId;
            }).toList();

            if (docs.isEmpty) {
              return const Center(child: Text('No Bills Found'));
            }
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
                          child: DataTable(
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 64,
                            columns: const [
                              DataColumn(label: Text('Receipt ID')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Item Names')),
                              DataColumn(label: Text('IMEIs')),
                              DataColumn(label: Text('Item Count')),
                              DataColumn(label: Text('Total Buying')),
                              DataColumn(label: Text('Total Estimated')),
                              DataColumn(label: Text('Total Selling')),
                              DataColumn(label: Text('Total Profit')),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text('${data['receipt_id'] ?? doc.id}'),
                                  ),
                                  DataCell(
                                    Text(_formatDate(data['created_at'])),
                                  ),
                                  DataCell(
                                    _ellipsisCell(
                                      '${data['item_names'] ?? ''}',
                                    ),
                                  ),
                                  DataCell(
                                    _ellipsisCell(_formatImeis(data['imeis'])),
                                  ),
                                  DataCell(Text('${data['item_count'] ?? ''}')),
                                  DataCell(
                                    Text('${data['total_buying_cost'] ?? ''}'),
                                  ),
                                  DataCell(
                                    Text(
                                      '${data['total_estimated_cost'] ?? ''}',
                                    ),
                                  ),
                                  DataCell(
                                    Text('${data['total_selling_cost'] ?? ''}'),
                                  ),
                                  DataCell(
                                    Text('${data['total_profit'] ?? ''}'),
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
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cash Received',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('cash_received')
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, cashSnap) {
                      if (cashSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!cashSnap.hasData) {
                        return const Center(child: Text('No Cash Records'));
                      }

                      final allCash = cashSnap.data!.docs;
                      final cashDocs = allCash.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['customer_id'] ?? '').toString() ==
                            widget.customerId;
                      }).toList();

                      if (cashDocs.isEmpty) {
                        return const Center(child: Text('No Cash Records'));
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
                                      ],
                                      rows: cashDocs.map((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(_formatDate(
                                                data['created_at']))),
                                            DataCell(Text(
                                                '${data['amount'] ?? ''}')),
                                            DataCell(
                                              _ellipsisCell(
                                                '${data['note'] ?? ''}',
                                                maxWidth: 300,
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              border: const Border(
                                top: BorderSide(color: Colors.black12),
                              ),
                            ),
                            child: Wrap(
                              spacing: 24,
                              runSpacing: 8,
                              children: [
                                Text('Total Cash: $totalCash'),
                                Text('Balance Due: ${totalSelling - totalCash}'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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
