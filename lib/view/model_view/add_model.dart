import 'package:flutter/material.dart';

class AddModelView extends StatefulWidget {
  const AddModelView({Key? key}) : super(key: key);

  @override
  State<AddModelView> createState() => _AddModelViewState();
}

class _AddModelViewState extends State<AddModelView> {
  final _formKey = GlobalKey<FormState>();
  final _modelNameController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _modelNameController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle form submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model added successfully')),
      );
      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Model')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _modelNameController,
                decoration: const InputDecoration(labelText: 'Model Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter model name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter color' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Model'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}