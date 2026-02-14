import 'package:flutter/material.dart';

class StockHome extends StatefulWidget {
  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  final List<Map<String, String>> stockData = [
    {'stock_id': '1', 'forign_model_id': '1', 'Mobile Name': 'Hot 60 4/128', 'Color': 'Black', 'description': 'camera24 pixel, battery 6000 Amp', 'Stock Count': '3', 'Coverage/Booked': ''},
    {'stock_id': '2', 'forign_model_id': '2', 'Mobile Name': 'Hot 60 8/128', 'Color': 'Black', 'description': 'camera24 pixel, battery 6000 Amp', 'Stock Count': '4', 'Coverage/Booked': ''},
    {'stock_id': '3', 'forign_model_id': '20', 'Mobile Name': 'Infinix 14 pro max 12/128', 'Color': 'Green', 'description': 'camera24 pixel, battery 6000 Amp', 'Stock Count': '4', 'Coverage/Booked': ''},
    {'stock_id': '4', 'forign_model_id': '16', 'Mobile Name': 'Redmi 12 12/128', 'Color': 'yellow', 'description': 'camera24 pixel, battery 6000 Amp', 'Stock Count': '2', 'Coverage/Booked': ''},
    {'stock_id': '5', 'forign_model_id': '17', 'Mobile Name': 'Redmi 12 4/128', 'Color': 'Green', 'description': 'camera24 pixel, battery 6000 Amp', 'Stock Count': '1', 'Coverage/Booked': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stock Management')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Stock ID')),
              DataColumn(label: Text('Model ID')),
              DataColumn(label: Text('Mobile Name')),
              DataColumn(label: Text('Color')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Stock Count')),
              DataColumn(label: Text('Coverage/Booked')),
            ],
            rows: stockData
                .map(
                  (item) => DataRow(cells: [
                    DataCell(Text(item['stock_id'] ?? '')),
                    DataCell(Text(item['forign_model_id'] ?? '')),
                    DataCell(Text(item['Mobile Name'] ?? '')),
                    DataCell(Text(item['Color'] ?? '')),
                    DataCell(Text(item['description'] ?? '')),
                    DataCell(Text(item['Stock Count'] ?? '')),
                    DataCell(Text(item['Coverage/Booked'] ?? '')),
                  ]),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}