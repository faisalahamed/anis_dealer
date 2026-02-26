import 'package:anis_dealer/view/bill_management/customer_wise_bill.dart';
import 'package:anis_dealer/view/customer_view/customer_home.dart';
import 'package:anis_dealer/view/mobile/add_mobile_home.dart';
import 'package:anis_dealer/view/mobile/add_new_mobile_multi.dart';
import 'package:anis_dealer/view/mobile/all_mobile_list.dart';
import 'package:anis_dealer/view/model_view/model_view.dart';
import 'package:anis_dealer/view/note_pad/note_pad_home.dart';
import 'package:anis_dealer/view/return_mobile/return_mobile_home.dart';
import 'package:anis_dealer/view/sell_mobile/sales_history_home.dart';
import 'package:anis_dealer/view/sell_mobile/sales_receipt.dart';
import 'package:anis_dealer/view/sell_mobile/sell_home.dart';
import 'package:anis_dealer/view/stock/stock_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        leadingWidth: 44,
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Today\'s Summary',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const _SummaryCard(),
            const SizedBox(height: 24),
            _SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: _NavTile(
                      icon: Icons.inventory_2,
                      label: 'কেনা',
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => MobileTableView(),
                        //   ),
                        // );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddNewMobileMultiPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NavTile(
                      icon: Icons.shopping_bag,
                      label: 'বেচা',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SellHome()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'খাতা সমূহ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NavTile(
                          icon: Icons.playlist_add_check_circle,
                          label: 'All Mobile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllMobileView(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.receipt_long,
                          label: 'বেচার খাতা',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SalesHistoryHome(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.people_alt,
                          label: 'বাকির খাতা',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerWiseBill(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.request_quote,
                          label: 'রশিদ লগ',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SalesReceiptHome(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feature সমূহ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NavTile(
                          icon: Icons.playlist_add_check_circle,
                          label: 'Add MODEL',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ModelView(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.people_alt,
                          label: 'Add Customer',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerHome(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.receipt_long,
                          label: 'স্টক',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StockHome(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.request_quote,
                          label: 'Return Mobile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReturnMobileHome(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NavTile(
                          icon: Icons.playlist_add_check_circle,
                          label: 'Notepad',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotePadHome(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.people_alt,
                          label: 'Expenses',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.receipt_long,
                          label: 'Reports',
                          onTap: () {},
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavTile(
                          icon: Icons.request_quote,
                          label: 'Feature 4',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sales_receipts')
          .snapshots(),
      builder: (context, snapshot) {
        num totalSoldValue = 0;
        num totalSoldCount = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = data['created_at'];
            if (createdAt is! Timestamp) continue;
            final dt = createdAt.toDate().toLocal();
            final day = DateTime(dt.year, dt.month, dt.day);
            if (day != today) continue;

            final count = data['item_count'];
            if (count is num) {
              totalSoldCount += count;
            } else {
              totalSoldCount += num.tryParse('$count') ?? 0;
            }

            final selling = data['total_selling_cost'];
            if (selling is num) {
              totalSoldValue += selling;
            } else {
              totalSoldValue += num.tryParse('$selling') ?? 0;
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('mobiles').snapshots(),
          builder: (context, stockSnap) {
            int stockCountLocal = 0;
            num stockValueLocal = 0;

            if (stockSnap.hasData) {
              for (final doc in stockSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final isSold = (data['isSold'] ?? false) == true;
                if (isSold) continue;
                stockCountLocal += 1;
                final buy = data['buyPrice'];
                if (buy is num) {
                  stockValueLocal += buy;
                } else {
                  stockValueLocal += num.tryParse('$buy') ?? 0;
                }
              }
            }
            int stockCount = 0;
            num stockValue = 0;

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final isSold = (data['isSold'] ?? false) == true;
                if (isSold) continue;
                stockCount += 1;
                final buy = data['buyPrice'];
                if (buy is num) {
                  stockValue += buy;
                } else {
                  stockValue += num.tryParse('$buy') ?? 0;
                }
              }
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCell(
                          title: 'মোট বিক্রিত পণ্যের মূল্য',
                          value: '${totalSoldValue.toStringAsFixed(0)} ৳',
                          valueColor: const Color(0xFF4CAF50),
                        ),
                      ),
                      const _VerticalDivider(),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('cash_received')
                              .snapshots(),
                          builder: (context, cashSnap) {
                            num totalCashToday = 0;
                            if (cashSnap.hasData) {
                              final now = DateTime.now();
                              final today = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              for (final doc in cashSnap.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final createdAt = data['created_at'];
                                if (createdAt is! Timestamp) continue;

                                final dt = createdAt.toDate().toLocal();
                                final day = DateTime(dt.year, dt.month, dt.day);
                                if (day != today) continue;

                                final amount = data['amount'];
                                if (amount is num) {
                                  totalCashToday += amount;
                                } else {
                                  totalCashToday +=
                                      num.tryParse('$amount') ?? 0;
                                }
                              }
                            }

                            return _MetricCell(
                              title: 'মোট প্রাপ্ত টাকা',
                              value: '${totalCashToday.toStringAsFixed(0)} ৳',
                              valueColor: const Color(0xFF1E5BD7),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCell(
                          title: 'মোট বিক্রিত পণ্যের সংখ্যা',
                          value: totalSoldCount.toStringAsFixed(0),
                          valueColor: const Color(0xFFE53935),
                        ),
                      ),
                      const _VerticalDivider(),
                      Expanded(
                        child: _MetricCell(
                          title: 'স্টক মূল্য',
                          value: '${stockValueLocal.toStringAsFixed(0)} ৳',
                          valueColor: const Color(0xFFE53935),
                        ),
                      ),
                      const _VerticalDivider(),
                      Expanded(
                        child: _MetricCell(
                          title: 'স্টক সংখ্যা',
                          value: '$stockCountLocal',
                          valueColor: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _MetricCell({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 48, width: 1, color: Colors.black12);
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF2C3E50)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
