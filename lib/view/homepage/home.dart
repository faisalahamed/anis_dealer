import 'package:anis_dealer/view/bill_management/customer_wise_bill.dart';
import 'package:anis_dealer/view/customer_view/customer_home.dart';
import 'package:anis_dealer/view/mobile/mobile_table.dart';
import 'package:anis_dealer/view/sell_mobile/sales_history_home.dart';
import 'package:anis_dealer/view/sell_mobile/sales_receipt.dart';
import 'package:anis_dealer/view/sell_mobile/sell_home.dart';
import 'package:anis_dealer/view/stock/stock_home.dart';
import 'package:flutter/material.dart';
import 'package:anis_dealer/view/model_view/model_view.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ModelView()),
                );
              },
              child: const Text('Add new Model'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MobileTableView()),
                );
              },
              child: const Text('Add new Mobile'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SellHome()),
                );
              },
              child: const Text('Sell Mobile'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StockHome()),
                );
              },
              child: const Text('View Stock'),
            ),

            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerHome()),
                );
              },
              child: const Text('Add Customer'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesHistoryHome()),
                );
              },
              child: const Text('View Sales History'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesReceiptHome()),
                );
              },
              child: const Text('View Sales Receipts'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerWiseBill()),
                );
              },
              child: const Text('View Customer Wise Bills'),
            ),
          ],
        ),
      ),
    );
  }
}
