import 'package:flutter/material.dart';

class ModelView extends StatefulWidget {
  const ModelView({Key? key}) : super(key: key);

  @override
  State<ModelView> createState() => _ModelViewState();
}

class _ModelViewState extends State<ModelView> {
  late List<Map<String, String>> models;

  @override
  void initState() {
    super.initState();
    models = [
      {
        'id': '1',
        'name': 'Hot 60 4/128',
        'color': 'Black',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '2',
        'name': 'Hot 60 8/128',
        'color': 'Black',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '3',
        'name': 'Hot 60 12/128',
        'color': 'Black',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '4',
        'name': 'Hot 60 4/128',
        'color': 'yellow',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '5',
        'name': 'Hot 60 8/128',
        'color': 'yellow',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '6',
        'name': 'Hot 60 12/128',
        'color': 'yellow',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '7',
        'name': 'Hot 60 12/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '8',
        'name': 'Hot 60 4/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '9',
        'name': 'Hot 60 8/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '10',
        'name': 'Hot 60 12/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '11',
        'name': 'Redmi 12 4/128',
        'color': 'Black',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '12',
        'name': 'Redmi 12 8/128',
        'color': 'Black',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '13',
        'name': 'Redmi 12 12/128',
        'color': 'Black',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '14',
        'name': 'Redmi 12 4/128',
        'color': 'yellow',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '15',
        'name': 'Redmi 12 8/128',
        'color': 'yellow',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '16',
        'name': 'Redmi 12 12/128',
        'color': 'yellow',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '17',
        'name': 'Redmi 12 4/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '18',
        'name': 'Redmi 12 8/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '19',
        'name': 'Redmi 12 12/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
      {
        'id': '20',
        'name': 'Infinix 14 pro max 12/128',
        'color': 'Green',
        'description': 'camera24 pixel, battery 6000 Amp',
      },
    ];
  }

  void _showAddModelDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final colorController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Model'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Model Name'),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
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
            onPressed: () {
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty &&
                  colorController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                setState(() {
                  models.add({
                    'id': idController.text,
                    'name': nameController.text,
                    'color': colorController.text,
                    'description': descriptionController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Models')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddModelDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Model'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width),
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Model Name')),
                      DataColumn(label: Text('Color')),
                      DataColumn(label: Text('Description')),
                    ],
                    rows: models.map((model) {
                      return DataRow(
                        cells: [
                          DataCell(Text(model['id']!)),
                          DataCell(Text(model['name']!)),
                          DataCell(Text(model['color']!)),
                          DataCell(Text(model['description']!)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
