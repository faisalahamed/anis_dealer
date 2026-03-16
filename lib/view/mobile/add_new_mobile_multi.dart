import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddNewMobileMultiPage extends StatefulWidget {
  const AddNewMobileMultiPage({super.key});

  @override
  State<AddNewMobileMultiPage> createState() => _AddNewMobileMultiPageState();
}

class _AddNewMobileMultiPageState extends State<AddNewMobileMultiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _imeiFormKey = GlobalKey<FormState>();

  final buyPriceController = TextEditingController();
  final estSellPriceController = TextEditingController();
  final imeiController = TextEditingController();
  final nameController = TextEditingController();
  final colorController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedModelId;
  String _selectedModelLabel = '';
  bool isSold = false;
  bool isSaving = false;

  final List<String> imeis = [];

  @override
  void dispose() {
    buyPriceController.dispose();
    estSellPriceController.dispose();
    imeiController.dispose();
    nameController.dispose();
    colorController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openAddImeiDialog() async {
    imeiController.clear();

    final scanned = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add IMEI'),
          content: Form(
            key: _imeiFormKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: imeiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'IMEI'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter IMEI';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Scan QR',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<String?>(
                      MaterialPageRoute(builder: (_) => const ScanPage()),
                    );
                    if (result != null && result.isNotEmpty) {
                      imeiController.text = result;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_imeiFormKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(imeiController.text.trim());
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (scanned != null && scanned.isNotEmpty) {
      setState(() => imeis.add(scanned));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final buyPrice = int.tryParse(buyPriceController.text);
    final estSellPrice = int.tryParse(estSellPriceController.text);

    if (buyPrice == null ||
        estSellPrice == null ||
        selectedModelId == null ||
        imeis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    final uniqueImeis = imeis.map((e) => e.trim()).where((e) => e.isNotEmpty);
    final imeiSet = <String>{};
    for (final imei in uniqueImeis) {
      if (!imeiSet.add(imei)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicate IMEI in list: $imei')),
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    final mobiles = _firestore.collection('mobiles');
    final existingImeis = <String>{};
    final imeiList = imeiSet.toList();
    for (var i = 0; i < imeiList.length; i += 10) {
      final chunk = imeiList.sublist(
        i,
        i + 10 > imeiList.length ? imeiList.length : i + 10,
      );
      final snap = await mobiles
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        existingImeis.add(doc.id);
      }
    }

    if (existingImeis.isNotEmpty) {
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'These IMEIs already exist: ${existingImeis.join(', ')}',
          ),
        ),
      );
      return;
    }

    final batch = _firestore.batch();
    for (final imei in imeiSet) {
      final doc = mobiles.doc(imei);
      batch.set(doc, {
        'iemi': int.tryParse(imei),
        'modelId': selectedModelId,
        'name': nameController.text,
        'color': colorController.text,
        'description': descriptionController.text,
        'buyPrice': buyPrice,
        'estimatedSellingPrice': estSellPrice,
        'isSold': isSold,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new Mobile'),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('models').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                return FormField<String>(
                  initialValue: selectedModelId,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  builder: (state) {
                    return InkWell(
                      onTap: () async {
                        final searchController = TextEditingController();
                        String query = '';

                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            final viewInsets = MediaQuery.of(
                              context,
                            ).viewInsets.bottom;
                            return Padding(
                              // padding: EdgeInsets.only(bottom: viewInsets),
                              padding: EdgeInsets.all(36),
                              child: StatefulBuilder(
                                builder: (context, setSheetState) {
                                  final filteredDocs = query.isEmpty
                                      ? docs
                                      : docs.where((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final name = (data['name'] ?? '')
                                              .toString()
                                              .toLowerCase();
                                          final color = (data['color'] ?? '')
                                              .toString()
                                              .toLowerCase();
                                          return name.contains(query) ||
                                              color.contains(query);
                                        }).toList();

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: TextField(
                                          controller: searchController,
                                          onChanged: (value) {
                                            setSheetState(() {
                                              query = value
                                                  .trim()
                                                  .toLowerCase();
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Search model...',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            suffixIcon: query.isEmpty
                                                ? null
                                                : IconButton(
                                                    icon: const Icon(
                                                      Icons.clear,
                                                    ),
                                                    onPressed: () {
                                                      searchController.clear();
                                                      setSheetState(() {
                                                        query = '';
                                                      });
                                                    },
                                                  ),
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: ListView.separated(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          shrinkWrap: true,
                                          itemCount: filteredDocs.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final doc = filteredDocs[index];
                                            final data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final modelName =
                                                (data['name'] ?? '').toString();
                                            final modelColor =
                                                (data['color'] ?? '')
                                                    .toString();
                                            return ListTile(
                                              title: Text(
                                                '$modelName -$modelColor',
                                              ),
                                              onTap: () => Navigator.of(
                                                context,
                                              ).pop(doc.id),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        );

                        if (selected == null) return;
                        setState(() {
                          selectedModelId = selected;
                          final selectedDoc = docs.firstWhere(
                            (doc) => doc.id == selected,
                          );
                          final data =
                              selectedDoc.data() as Map<String, dynamic>;
                          nameController.text = (data['name'] ?? '').toString();
                          colorController.text = (data['color'] ?? '')
                              .toString();
                          descriptionController.text =
                              (data['description'] ?? '').toString();
                          _selectedModelLabel =
                              '${data['name'] ?? ''}-${data['color'] ?? ''}';
                        });
                        state.didChange(selected);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Model ID',
                          errorText: state.errorText,
                        ),
                        child: Text(
                          _selectedModelLabel.isEmpty
                              ? 'Select Model'
                              : _selectedModelLabel,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Mobile Name'),
              readOnly: true,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: colorController,
              decoration: const InputDecoration(labelText: 'Color'),
              readOnly: true,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              readOnly: true,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyPriceController,
              decoration: const InputDecoration(labelText: 'Buy Price'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: estSellPriceController,
              decoration: const InputDecoration(labelText: 'Est. Sell Price'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            // Row(
            //   children: [
            //     Checkbox(
            //       value: isSold,
            //       onChanged: (value) {
            //         setState(() {
            //           isSold = value ?? false;
            //         });
            //       },
            //     ),
            //     const Text('Sold'),
            //   ],
            // ),
            const SizedBox(height: 16),
            const Text('IMEIs', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.black26),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(72),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        's/n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'IMEI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Remove',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...List.generate(imeis.length, (i) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('${i + 1}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(imeis[i]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () {
                            setState(() {
                              imeis.removeAt(i);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _openAddImeiDialog,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add/Scan IMEI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan IMEI')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue ?? '';
            if (code.isNotEmpty) Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}
