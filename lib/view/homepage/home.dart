import 'package:anis_dealer/view/mobile/mobile_table.dart';
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
            ElevatedButton(onPressed: () {}, child: const Text('Sell Mobile')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: () {}, child: const Text('Stock View`')),
          ],
        ),
      ),
    );
  }
}
