import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import 'customer_edit_screen.dart';
import 'customer_khata_detail_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncCustomers = ref.watch(customersWithBalanceProvider);

    return Column(
      children: [
        Expanded(
          child: asyncCustomers.when(
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                  child: Text('અહીં હજુ કોઈ ગ્રાહક ઉમેરાયેલ નથી.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final balance = item.balance;
                  final color = balance <= 0
                      ? Colors.green
                      : (balance > 500 ? Colors.red : Colors.orange);
                  return ListTile(
                    leading: Icon(
                      Icons.person,
                      color: color,
                    ),
                    title: Text(item.customer.name),
                    subtitle: Text(
                      'બાકી: ${Formatters.formatCurrency(balance)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerKhataDetailScreen(
                            customer: item.customer,
                          ),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('ભૂલ: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const CustomerEditScreen(),
                  ),
                );
                if (created == true && mounted) {
                  ref.invalidate(customersWithBalanceProvider);
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('નવો ગ્રાહક'),
            ),
          ),
        ),
      ],
    );
  }
}
