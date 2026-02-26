import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ReturnMobileHome extends StatefulWidget {
  const ReturnMobileHome({super.key});

  @override
  State<ReturnMobileHome> createState() => _ReturnMobileHomeState();
}

class _ReturnMobileHomeState extends State<ReturnMobileHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value') ?? 0;
  }

  List<String> _toStringList(dynamic value) {
    if (value is Iterable) {
      return value.map((e) => '$e').toList();
    }
    return <String>[];
  }

  Future<void> _scanAndReturn() async {
    final code = await Navigator.of(
      context,
    ).push<String?>(MaterialPageRoute(builder: (_) => const _ScanImeiPage()));
    if (code == null || code.trim().isEmpty) return;
    await _handleReturnByImei(code.trim());
  }

  Future<void> _openManualInputDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter IMEI'),
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
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Find'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    await _handleReturnByImei(result);
  }

  Future<void> _handleReturnByImei(String rawImei) async {
    final imei = int.tryParse(rawImei);
    if (imei == null) {
      _showMessage('Invalid IMEI');
      return;
    }

    final query = await _firestore
        .collection('mobiles')
        .where('iemi', isEqualTo: imei)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      _showMessage('IMEI not found: $imei');
      return;
    }

    final doc = query.docs.first;
    final data = doc.data();
    final isSold = (data['isSold'] ?? false) == true;

    if (!isSold) {
      _showMessage('This mobile is already in stock');
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Return'),
        content: Text(
          'Return IMEI $imei to stock?\n\n'
          'Model: ${data['name'] ?? ''}\n'
          'Color: ${data['color'] ?? ''}\n'
          'Sold To: ${data['soldToCustomerName'] ?? ''}',
        ),
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

    if (confirm != true) return;

    final salesQuery = await _firestore
        .collection('sales')
        .where('forign_mobile_id', isEqualTo: doc.id)
        .get();

    final receiptQuery = await _firestore
        .collection('sales_receipts')
        .where('item_ids', arrayContains: doc.id)
        .get();

    num removedBuying = 0;
    num removedEstimated = 0;
    num removedSelling = 0;
    for (final saleDoc in salesQuery.docs) {
      final saleData = saleDoc.data();
      removedBuying += _toNum(saleData['f_buying_price']);
      removedEstimated += _toNum(saleData['f_estimated_selling_price']);
      removedSelling += _toNum(saleData['selling_price']);
    }

    final batch = _firestore.batch();

    batch.update(_firestore.collection('mobiles').doc(doc.id), {
      'isSold': false,
      'soldAt': FieldValue.delete(),
      'soldToCustomerId': FieldValue.delete(),
      'soldToCustomerName': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final saleDoc in salesQuery.docs) {
      batch.delete(saleDoc.reference);
    }

    for (final receiptDoc in receiptQuery.docs) {
      final receipt = receiptDoc.data();
      final itemIds = _toStringList(receipt['item_ids']);
      final itemNames = _toStringList(receipt['item_names_list']);
      final imeis = receipt['imeis'] is Iterable
          ? List<dynamic>.from(receipt['imeis'] as Iterable)
          : <dynamic>[];
      final prices = receipt['item_selling_prices'] is Iterable
          ? List<num>.from(
              (receipt['item_selling_prices'] as Iterable).map(_toNum),
            )
          : <num>[];

      final idx = itemIds.indexOf(doc.id);
      if (idx < 0) continue;

      if (idx < itemIds.length) itemIds.removeAt(idx);
      if (idx < itemNames.length) itemNames.removeAt(idx);
      if (idx < imeis.length) imeis.removeAt(idx);
      if (idx < prices.length) prices.removeAt(idx);

      if (itemIds.isEmpty) {
        batch.delete(receiptDoc.reference);
        continue;
      }

      final oldBuying = _toNum(receipt['total_buying_cost']);
      final oldEstimated = _toNum(receipt['total_estimated_cost']);
      final oldSelling = _toNum(receipt['total_selling_cost']);
      final newBuying = (oldBuying - removedBuying).clamp(0, double.infinity);
      final newEstimated = (oldEstimated - removedEstimated).clamp(
        0,
        double.infinity,
      );
      final newSelling = prices.fold<num>(0, (acc, v) => acc + v);
      final effectiveSelling = newSelling == 0
          ? (oldSelling - removedSelling).clamp(0, double.infinity)
          : newSelling;

      batch.update(receiptDoc.reference, {
        'item_ids': itemIds,
        'item_names_list': itemNames,
        'item_names': itemNames.join(', '),
        'imeis': imeis,
        'item_selling_prices': prices,
        'item_count': itemIds.length,
        'total_buying_cost': newBuying,
        'total_estimated_cost': newEstimated,
        'total_selling_cost': effectiveSelling,
        'total_profit': effectiveSelling - newBuying,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (!mounted) return;
    _showMessage('Mobile returned and related records updated');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Return Mobile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Return Sold Mobile To Stock',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _scanAndReturn,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan IMEI'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openManualInputDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Type IMEI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanImeiPage extends StatelessWidget {
  const _ScanImeiPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan IMEI')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue ?? '';
            if (code.isNotEmpty) {
              Navigator.of(context).pop(code);
            }
          }
        },
      ),
    );
  }
}
