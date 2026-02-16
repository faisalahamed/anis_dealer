import 'package:flutter/material.dart';

class MobileTableView extends StatefulWidget {
  const MobileTableView({super.key});

  @override
  State<MobileTableView> createState() => _MobileTableViewState();
}

class _MobileTableViewState extends State<MobileTableView> {
  late List<MobileModel> mobileModels;

  @override
  void initState() {
    super.initState();
    mobileModels = _getMobileData();
    _sortByDate();
  }

  void _sortByDate() {
    mobileModels.sort((a, b) => b.mobileId.compareTo(a.mobileId));
  }

  List<MobileModel> _getMobileData() {
    return [
      MobileModel(1, 'Thursday, February 05, 2026', 1000001, 1, 'Hot 60 4/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, true),
      MobileModel(2, 'Thursday, February 05, 2026', 1000002, 1, 'Hot 60 4/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, false),
      MobileModel(3, 'Thursday, February 05, 2026', 1000003, 1, 'Hot 60 4/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, true),
      MobileModel(4, 'Friday, February 06, 2026', 1000004, 1, 'Hot 60 4/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, true),
      MobileModel(5, 'Saturday, February 07, 2026', 1000005, 2, 'Hot 60 8/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, true),
      MobileModel(6, 'Sunday, February 08, 2026', 1000006, 2, 'Hot 60 8/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, true),
      MobileModel(7, 'Monday, February 09, 2026', 1000007, 2, 'Hot 60 8/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, true),
      MobileModel(8, 'Tuesday, February 10, 2026', 1000008, 2, 'Hot 60 8/128', 'Black', 'camera24 pixel, battery 6000 Amp', 100, 110, true),
      MobileModel(9, 'Wednesday, February 11, 2026', 1000009, 20, 'Infinix 14 pro max 12/128', 'Green', 'camera24 pixel, battery 6000 Amp', 200, 210, true),
      MobileModel(10, 'Thursday, February 12, 2026', 1000010, 20, 'Infinix 14 pro max 12/129', 'Green', 'camera24 pixel, battery 6000 Amp', 200, 210, true),
      MobileModel(11, 'Friday, February 13, 2026', 1000011, 20, 'Infinix 14 pro max 12/130', 'Green', 'camera24 pixel, battery 6000 Amp', 200, 210, true),
      MobileModel(12, 'Saturday, February 14, 2026', 1000012, 20, 'Infinix 14 pro max 12/131', 'Green', 'camera24 pixel, battery 6000 Amp', 200, 210, true),
      MobileModel(13, 'Sunday, February 15, 2026', 1000013, 16, 'Redmi 12 12/128', 'yellow', 'camera24 pixel, battery 6000 Amp', 300, 320, true),
      MobileModel(14, 'Monday, February 16, 2026', 1000014, 16, 'Redmi 12 12/128', 'yellow', 'camera24 pixel, battery 6000 Amp', 300, 320, true),
      MobileModel(15, 'Tuesday, February 17, 2026', 1000015, 17, 'Redmi 12 4/128', 'Green', 'camera24 pixel, battery 6000 Amp', 300, 320, true),
    ];
  }

  void _addNewMobile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add new mobile functionality')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mobile Stock')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addNewMobile,
              icon: Icon(Icons.add),
              label: Text('New Mobile'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Mobile ID')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('IEMI')),
                    DataColumn(label: Text('Model ID')),
                    DataColumn(label: Text('Mobile Name')),
                    DataColumn(label: Text('Color')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Buy Price')),
                    DataColumn(label: Text('Est. Sell Price')),
                    DataColumn(label: Text('Sold')),
                  ],
                  rows: mobileModels
                      .map(
                        (model) => DataRow(
                          cells: [
                            DataCell(Text(model.mobileId.toString())),
                            DataCell(Text(model.date)),
                            DataCell(Text(model.iemi.toString())),
                            DataCell(Text(model.foreignModelId.toString())),
                            DataCell(Text(model.mobileName)),
                            DataCell(Text(model.color)),
                            DataCell(Text(model.description)),
                            DataCell(Text(model.buyPrice.toString())),
                            DataCell(Text(model.estimatedSellingPrice.toString())),
                            DataCell(Text(model.isSold ? 'Yes' : 'No')),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileModel {
  final int mobileId;
  final String date;
  final int iemi;
  final int foreignModelId;
  final String mobileName;
  final String color;
  final String description;
  final int buyPrice;
  final int estimatedSellingPrice;
  final bool isSold;

  MobileModel(
    this.mobileId,
    this.date,
    this.iemi,
    this.foreignModelId,
    this.mobileName,
    this.color,
    this.description,
    this.buyPrice,
    this.estimatedSellingPrice,
    this.isSold,
  );
}