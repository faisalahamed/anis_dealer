import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:anis_dealer/view/bill_management/customer_bill_details.dart';

class CustomerWiseBill extends StatefulWidget {
  const CustomerWiseBill({super.key});

  @override
  State<CustomerWiseBill> createState() => _CustomerWiseBillState();
}

class _CustomerWiseBillState extends State<CustomerWiseBill> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('d MMM h:mm a').format(value.toDate().toLocal());
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Wise Bills')),
      body: ScrollConfiguration(
        behavior: const _AppScrollBehavior(),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('customers').snapshots(),
          builder: (context, customerSnap) {
            if (customerSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!customerSnap.hasData || customerSnap.data!.docs.isEmpty) {
              return const Center(child: Text('No Customers Found'));
            }

            final customers = customerSnap.data!.docs;

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('sales_receipts').snapshots(),
              builder: (context, receiptSnap) {
                if (receiptSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final receipts = receiptSnap.data?.docs ?? [];
                final Map<String, Map<String, dynamic>> totals = {};

                for (final doc in receipts) {
                  final data = doc.data() as Map<String, dynamic>;
                  final customerId = (data['customer_id'] ?? '').toString();
                  if (customerId.isEmpty) continue;

                  final t = totals.putIfAbsent(customerId, () {
                    return {
                      'total_buying_cost': 0,
                      'total_estimated_cost': 0,
                      'total_selling_cost': 0,
                      'total_profit': 0,
                      'last_date': data['created_at'],
                    };
                  });

                  num _toNum(dynamic v) =>
                      v is num ? v : num.tryParse('$v') ?? 0;

                  t['total_buying_cost'] =
                      (t['total_buying_cost'] as num) +
                          _toNum(data['total_buying_cost']);
                  t['total_estimated_cost'] =
                      (t['total_estimated_cost'] as num) +
                          _toNum(data['total_estimated_cost']);
                  t['total_selling_cost'] =
                      (t['total_selling_cost'] as num) +
                          _toNum(data['total_selling_cost']);
                  t['total_profit'] =
                      (t['total_profit'] as num) +
                          _toNum(data['total_profit']);

                  final current = t['last_date'];
                  if (current is Timestamp && data['created_at'] is Timestamp) {
                    if ((data['created_at'] as Timestamp)
                        .toDate()
                        .isAfter(current.toDate())) {
                      t['last_date'] = data['created_at'];
                    }
                  } else if (current == null) {
                    t['last_date'] = data['created_at'];
                  }
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
                        child: DataTable(
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 64,
                          columns: const [
                            DataColumn(label: Text('Customer ID')),
                            DataColumn(label: Text('Customer Name')),
                            DataColumn(label: Text('Customer Mobile')),
                            DataColumn(label: Text('Last Bill Date')),
                            DataColumn(label: Text('Total Buying')),
                            DataColumn(label: Text('Total Estimated')),
                            DataColumn(label: Text('Total Selling')),
                            DataColumn(label: Text('Total Profit')),
                            DataColumn(label: Text('Details')),
                          ],
                          rows: customers.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final totalsRow = totals[doc.id] ?? {};
                            return DataRow(
                              cells: [
                                DataCell(Text(doc.id)),
                                DataCell(Text('${data['name'] ?? ''}')),
                                DataCell(Text('${data['mobile'] ?? ''}')),
                                DataCell(
                                  Text(_formatDate(totalsRow['last_date'])),
                                ),
                                DataCell(Text(
                                    '${totalsRow['total_buying_cost'] ?? 0}')),
                                DataCell(Text(
                                    '${totalsRow['total_estimated_cost'] ?? 0}')),
                                DataCell(Text(
                                    '${totalsRow['total_selling_cost'] ?? 0}')),
                                DataCell(Text(
                                    '${totalsRow['total_profit'] ?? 0}')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 18),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CustomerBillDetails(
                                            customerId: doc.id,
                                            customerName:
                                                (data['name'] ?? '').toString(),
                                            customerMobile:
                                                (data['mobile'] ?? '').toString(),
                                          ),
                                        ),
                                      );
                                    },
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
