import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddNewMobilePage extends StatefulWidget {
  const AddNewMobilePage({super.key});

  @override
  State<AddNewMobilePage> createState() => _AddNewMobilePageState();
}

class _AddNewMobilePageState extends State<AddNewMobilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final iemiController = TextEditingController();
  final nameController = TextEditingController();
  final colorController = TextEditingController();
  final descriptionController = TextEditingController();
  final buyPriceController = TextEditingController();
  final estSellPriceController = TextEditingController();

  String? selectedModelId;
  bool isSold = false;
  bool isSaving = false;

  @override
  void dispose() {
    iemiController.dispose();
    nameController.dispose();
    colorController.dispose();
    descriptionController.dispose();
    buyPriceController.dispose();
    estSellPriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final iemi = int.tryParse(iemiController.text);
    final buyPrice = int.tryParse(buyPriceController.text);
    final estSellPrice = int.tryParse(estSellPriceController.text);

    if (iemi == null ||
        buyPrice == null ||
        estSellPrice == null ||
        selectedModelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    await _firestore.collection('mobiles').add({
      'iemi': iemi,
      'modelId': selectedModelId,
      'name': nameController.text,
      'color': colorController.text,
      'description': descriptionController.text,
      'buyPrice': buyPrice,
      'estimatedSellingPrice': estSellPrice,
      'isSold': isSold,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Mobile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
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

                return DropdownButtonFormField<String>(
                  value: selectedModelId,
                  decoration: const InputDecoration(labelText: 'Model ID'),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final modelName = (data['name'] ?? '').toString();
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text('${doc.id} - $modelName'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedModelId = value;
                      final selected = docs.firstWhere(
                        (doc) => doc.id == value,
                      );
                      final data = selected.data() as Map<String, dynamic>;
                      nameController.text = (data['name'] ?? '').toString();
                      colorController.text = (data['color'] ?? '').toString();
                      descriptionController.text = (data['description'] ?? '')
                          .toString();
                    });
                  },
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
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
            Row(
              children: [
                Checkbox(
                  value: isSold,
                  onChanged: (value) {
                    setState(() {
                      isSold = value ?? false;
                    });
                  },
                ),
                const Text('Sold'),
              ],
            ),

            TextFormField(
              controller: iemiController,
              decoration: const InputDecoration(labelText: 'IEMI'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
