import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SellHome extends StatefulWidget {
  const SellHome({super.key});

  @override
  State<SellHome> createState() => _SellHomeState();
}

class _SellHomeState extends State<SellHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedCustomerId;
  final customerNameController = TextEditingController();
  final customerMobileController = TextEditingController();
  final customerAddressController = TextEditingController();

  final List<_SelectedMobile> selectedMobiles = [];

  @override
  void dispose() {
    customerNameController.dispose();
    customerMobileController.dispose();
    customerAddressController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('d MMM h:mm a').format(value.toDate().toLocal());
    }
    return '';
  }

  Future<void> _scanAndAddMobile() async {
    final code = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const _ScanPage()),
    );

    if (code == null || code.trim().isEmpty) return;
    await _addImei(code.trim());
  }

  Future<void> _addImei(String raw) async {
    final imei = int.tryParse(raw);
    if (imei == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid IMEI')),
      );
      return;
    }

    if (selectedMobiles.any((m) => m.iemi == imei)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IMEI already added: $imei')),
      );
      return;
    }

    final query = await _firestore
        .collection('mobiles')
        .where('iemi', isEqualTo: imei)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IMEI not found: $imei')),
      );
      return;
    }

    final doc = query.docs.first;
    final data = doc.data();
    final isSold = (data['isSold'] ?? false) == true;
    if (isSold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IMEI already sold: $imei')),
      );
      return;
    }

    setState(() {
      selectedMobiles.add(_SelectedMobile(doc.id, data));
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

  num get _totalSellingPrice {
    num total = 0;
    for (final m in selectedMobiles) {
      total += _toNum(m.data['estimatedSellingPrice']);
    }
    return total;
  }

  Future<void> _confirmSell() async {
    if (selectedCustomerId == null || selectedMobiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select customer and add mobiles')),
      );
      return;
    }

    final batch = _firestore.batch();
    for (final item in selectedMobiles) {
      final docRef = _firestore.collection('mobiles').doc(item.docId);
      final data = item.data;
      final buyPrice = _toNum(data['buyPrice']);
      final estimatedSell = _toNum(data['estimatedSellingPrice']);
      final sellingPrice = estimatedSell;
      final profit = sellingPrice - buyPrice;

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
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sell confirmed')),
    );
    setState(() {
      selectedMobiles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell Mobile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Customer',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                      child: Text('${doc.id} - $name'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCustomerId = value;
                      final selected =
                          docs.firstWhere((doc) => doc.id == value);
                      final data =
                          selected.data() as Map<String, dynamic>;
                      customerNameController.text =
                          (data['name'] ?? '').toString();
                      customerMobileController.text =
                          (data['mobile'] ?? '').toString();
                      customerAddressController.text =
                          (data['address'] ?? '').toString();
                    });
                  },
                  decoration:
                      const InputDecoration(labelText: 'Select Customer'),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customerNameController,
                    decoration:
                        const InputDecoration(labelText: 'Customer Name'),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: customerMobileController,
                    decoration:
                        const InputDecoration(labelText: 'Customer Mobile'),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('s/n')),
                      DataColumn(label: Text('date_bought')),
                      DataColumn(label: Text('IEMI')),
                      DataColumn(label: Text('forign_model_id')),
                      DataColumn(label: Text('mobile_name')),
                      DataColumn(label: Text('color')),
                      DataColumn(label: Text('description')),
                      DataColumn(label: Text('buy_price')),
                      DataColumn(label: Text('estimated_Selling_price')),
                      DataColumn(label: Text('is_sold')),
                      DataColumn(label: Text('remove')),
                    ],
                    rows: List.generate(selectedMobiles.length, (index) {
                      final item = selectedMobiles[index];
                      final data = item.data;
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(_formatDate(data['createdAt']))),
                          DataCell(Text('${data['iemi'] ?? ''}')),
                          DataCell(Text('${data['modelId'] ?? ''}')),
                          DataCell(Text('${data['name'] ?? ''}')),
                          DataCell(Text('${data['color'] ?? ''}')),
                          DataCell(Text('${data['description'] ?? ''}')),
                          DataCell(Text('${data['buyPrice'] ?? ''}')),
                          DataCell(
                              Text('${data['estimatedSellingPrice'] ?? ''}')),
                          DataCell(
                              Text((data['isSold'] ?? false) ? 'Yes' : 'No')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                setState(() {
                                  selectedMobiles.removeAt(index);
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total selling Price: $_totalSellingPrice',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _confirmSell,
                  child: const Text('Confirm Sell'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
