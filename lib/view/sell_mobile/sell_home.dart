import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/gestures.dart';

class SellHome extends StatefulWidget {
  const SellHome({super.key});

  @override
  State<SellHome> createState() => _SellHomeState();
}

class _SellHomeState extends State<SellHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  String? selectedCustomerId;
  final customerNameController = TextEditingController();
  final customerMobileController = TextEditingController();
  final customerAddressController = TextEditingController();

  final List<_SelectedMobile> selectedMobiles = [];
  final Map<String, TextEditingController> _sellingPriceControllers = {};

  @override
  void dispose() {
    customerNameController.dispose();
    customerMobileController.dispose();
    customerAddressController.dispose();
    for (final c in _sellingPriceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('d MMM h:mm a').format(value.toDate().toLocal());
    }
    return '';
  }

  Future<void> _scanAndAddMobile() async {
    final code = await Navigator.of(
      context,
    ).push<String?>(MaterialPageRoute(builder: (_) => const _ScanPage()));

    if (code == null || code.trim().isEmpty) return;
    await _addImei(code.trim());
  }

  Future<void> _addImei(String raw) async {
    final imei = int.tryParse(raw);
    if (imei == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid IMEI')));
      return;
    }

    if (selectedMobiles.any((m) => m.iemi == imei)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('IMEI already added: $imei')));
      return;
    }

    final query = await _firestore
        .collection('mobiles')
        .where('iemi', isEqualTo: imei)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('IMEI not found: $imei')));
      return;
    }

    final doc = query.docs.first;
    final data = doc.data();
    final isSold = (data['isSold'] ?? false) == true;
    if (isSold) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('IMEI already sold: $imei')));
      return;
    }

    setState(() {
      selectedMobiles.add(_SelectedMobile(doc.id, data));
      _sellingPriceControllers[doc.id] = TextEditingController(
        text: '${data['estimatedSellingPrice'] ?? ''}',
      );
    });
  }

  Future<void> _openImeiInputDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add IMEI'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'IMEI'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    await _addImei(result);
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  num get _totalEstimatedSellingPrice {
    num total = 0;
    for (final m in selectedMobiles) {
      total += _toNum(m.data['estimatedSellingPrice']);
    }
    return total;
  }

  num get _totalInputSellingPrice {
    num total = 0;
    for (final m in selectedMobiles) {
      final controller = _sellingPriceControllers[m.docId];
      total += _toNum(controller?.text ?? 0);
    }
    return total;
  }

  num get _totalBuyingPrice {
    num total = 0;
    for (final m in selectedMobiles) {
      total += _toNum(m.data['buyPrice']);
    }
    return total;
  }

  num get _totalProfitOrLoss => _totalInputSellingPrice - _totalBuyingPrice;

  Future<void> _confirmSell() async {
    if (selectedCustomerId == null || selectedMobiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select customer and add mobiles')),
      );
      return;
    }

    num totalBuying = 0;
    num totalEstimated = 0;
    num totalSelling = 0;
    final itemNames = <String>[];
    final itemIds = <String>[];
    final imeis = <dynamic>[];
    final itemSellingPrices = <num>[];

    final batch = _firestore.batch();
    for (final item in selectedMobiles) {
      final docRef = _firestore.collection('mobiles').doc(item.docId);
      final data = item.data;
      final buyPrice = _toNum(data['buyPrice']);
      final estimatedSell = _toNum(data['estimatedSellingPrice']);
      final controller = _sellingPriceControllers[item.docId];
      final raw = controller?.text.trim() ?? '';
      if (raw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selling price required for IMEI ${data['iemi'] ?? ''}',
            ),
          ),
        );
        return;
      }
      final sellingPrice = _toNum(raw);
      if (sellingPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid selling price for IMEI ${data['iemi'] ?? ''}',
            ),
          ),
        );
        return;
      }
      final minPrice = buyPrice * 0.90;
      final maxPrice = buyPrice * 1.20;
      if (sellingPrice < minPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selling price too low for IMEI ${data['iemi'] ?? ''}. Min: ${minPrice.toStringAsFixed(2)}',
            ),
          ),
        );
        return;
      }
      if (sellingPrice > maxPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selling price too high for IMEI ${data['iemi'] ?? ''}. Max: ${maxPrice.toStringAsFixed(2)}',
            ),
          ),
        );
        return;
      }
      final profit = sellingPrice - buyPrice;

      totalBuying += buyPrice;
      totalEstimated += estimatedSell;
      totalSelling += sellingPrice;
      itemNames.add('${data['name'] ?? ''}'.trim());
      itemIds.add(item.docId);
      imeis.add(data['iemi']);
      itemSellingPrices.add(sellingPrice);

      final saleRef = _firestore.collection('sales').doc();
      batch.set(saleRef, {
        'selling_id': saleRef.id,
        'selling_date': FieldValue.serverTimestamp(),
        'forign_mobile_id': item.docId,
        'f_mobile_name': data['name'],
        'f_color': data['color'],
        'f_iemi': data['iemi'],
        'f_buying_price': buyPrice,
        'f_estimated_selling_price': estimatedSell,
        'selling_price': sellingPrice,
        'profit': profit,
        'f_customer_id': selectedCustomerId,
        'f_customer_name': customerNameController.text,
        'f_customer_mobile': customerMobileController.text,
        'f_customer_address': customerAddressController.text,
      });

      batch.update(docRef, {
        'isSold': true,
        'soldAt': FieldValue.serverTimestamp(),
        'soldToCustomerId': selectedCustomerId,
        'soldToCustomerName': customerNameController.text,
      });
    }

    final receiptRef = _firestore.collection('sales_receipts').doc();
    batch.set(receiptRef, {
      'receipt_id': receiptRef.id,
      'created_at': FieldValue.serverTimestamp(),
      'customer_id': selectedCustomerId,
      'customer_name': customerNameController.text,
      'customer_mobile': customerMobileController.text,
      'customer_address': customerAddressController.text,
      'item_names': itemNames.join(', '),
      'item_names_list': itemNames,
      'item_ids': itemIds,
      'imeis': imeis,
      'item_selling_prices': itemSellingPrices,
      'item_count': selectedMobiles.length,
      'total_buying_cost': totalBuying,
      'total_estimated_cost': totalEstimated,
      'total_selling_cost': totalSelling,
      'total_profit': totalSelling - totalBuying,
    });

    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sell confirmed')));
    setState(() {
      selectedMobiles.clear();
      for (final c in _sellingPriceControllers.values) {
        c.dispose();
      }
      _sellingPriceControllers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Mobile'),
        actions: [
          TextButton(
            onPressed: _confirmSell,
            child: const Text(
              'Confirm Sell',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Customer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('customers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                final docs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  value: selectedCustomerId,
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString();
                    return DropdownMenuItem(
                      value: doc.id,
                      // child: Text('${doc.id} - $name'),
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCustomerId = value;
                      final selected = docs.firstWhere(
                        (doc) => doc.id == value,
                      );
                      final data = selected.data() as Map<String, dynamic>;
                      customerNameController.text = (data['name'] ?? '')
                          .toString();
                      customerMobileController.text = (data['mobile'] ?? '')
                          .toString();
                      customerAddressController.text = (data['address'] ?? '')
                          .toString();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Customer',
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: customerMobileController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Mobile',
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customerAddressController,
              decoration: const InputDecoration(labelText: 'Address'),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ScrollConfiguration(
                behavior: const _AppScrollBehavior(),
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
                          columns: const [
                            DataColumn(label: Text('s/n')),
                            // DataColumn(label: Text('date_bought')),
                            DataColumn(label: Text('IEMI')),
                            // DataColumn(label: Text('forign_model_id')),
                            DataColumn(label: Text('mobile_name')),
                            DataColumn(label: Text('color')),
                            // DataColumn(label: Text('description')),
                            DataColumn(label: Text('buy_price')),
                            DataColumn(label: Text('estimated_Selling_price')),
                            DataColumn(label: Text('selling_price')),
                            DataColumn(label: Text('remove')),
                          ],
                          rows: List.generate(selectedMobiles.length, (index) {
                            final item = selectedMobiles[index];
                            final data = item.data;
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                // DataCell(Text(_formatDate(data['createdAt']))),
                                DataCell(Text('${data['iemi'] ?? ''}')),
                                // DataCell(Text('${data['modelId'] ?? ''}')),
                                DataCell(Text('${data['name'] ?? ''}')),
                                DataCell(Text('${data['color'] ?? ''}')),
                                // DataCell(Text('${data['description'] ?? ''}')),
                                DataCell(Text('${data['buyPrice'] ?? ''}')),
                                DataCell(
                                  Text(
                                    '${data['estimatedSellingPrice'] ?? ''}',
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 110,
                                    child: TextField(
                                      controller:
                                          _sellingPriceControllers[item.docId],
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        selectedMobiles.removeAt(index);
                                        final controller =
                                            _sellingPriceControllers.remove(
                                              item.docId,
                                            );
                                        controller?.dispose();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isKeyboardOpen) ...[
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total Buying Price: $_totalBuyingPrice',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total Estimated selling Price: $_totalEstimatedSellingPrice',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total Inputed selling Price: $_totalInputSellingPrice',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _totalProfitOrLoss >= 0
                      ? 'Total Profit: ${_totalProfitOrLoss.toStringAsFixed(2)}'
                      : 'Total Loss: ${_totalProfitOrLoss.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _totalProfitOrLoss >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _scanAndAddMobile,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan IEMI'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openImeiInputDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Enter IEMI'),
                  ),
                ],
              ),
            ],
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

class _SelectedMobile {
  final String docId;
  final Map<String, dynamic> data;

  _SelectedMobile(this.docId, this.data);

  int get iemi => data['iemi'] is int
      ? data['iemi'] as int
      : int.tryParse('${data['iemi']}') ?? 0;
}

class _ScanPage extends StatelessWidget {
  const _ScanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan IEMI')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue ?? '';
            if (code.isNotEmpty) Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}
