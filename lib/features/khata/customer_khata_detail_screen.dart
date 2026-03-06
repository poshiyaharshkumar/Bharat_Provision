import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/numpad.dart';
import '../../data/models/customer.dart';
import '../../data/models/khata_entry.dart';
import '../../data/providers.dart';

class CustomerKhataDetailScreen extends ConsumerStatefulWidget {
  const CustomerKhataDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<CustomerKhataDetailScreen> createState() =>
      _CustomerKhataDetailScreenState();
}

class _CustomerKhataDetailScreenState
    extends ConsumerState<CustomerKhataDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final customerId = widget.customer.id;
    if (customerId == null) {
      return const Scaffold(
        body: Center(child: Text('અમાન્ય ગ્રાહક')),
      );
    }

    final balanceAsync = ref.watch(customerBalanceProvider(customerId));
    final entriesAsync = ref.watch(customerEntriesProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerBalanceProvider(customerId));
          ref.invalidate(customerEntriesProvider(customerId));
          ref.invalidate(customersWithBalanceProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            balanceAsync.when(
              data: (balance) {
                final color =
                    balance <= 0 ? Colors.green : Colors.red;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ચાલુ બાકી'),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(balance),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('બાકી લાવવામાં ભૂલ'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddUdhar(context, customerId),
                    icon: const Icon(Icons.add),
                    label: const Text('ઉધાર ઉમેરો'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRecordPayment(context, customerId),
                    icon: const Icon(Icons.payment),
                    label: const Text('ચુકવણી નોંધાવો'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'ઇતિહાસ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('હજુ કોઈ એન્ટ્રી નથી.')),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final isDebit = e.type == 'debit';
                    return ListTile(
                      leading: Icon(
                        isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isDebit ? Colors.red : Colors.green,
                      ),
                      title: Text(
                        isDebit ? 'ઉધાર' : 'ચુકવણી',
                      ),
                      subtitle: Text(
                        '${Formatters.formatDate(DateTime.fromMillisecondsSinceEpoch(e.dateTimeMillis))} ${e.note ?? ''}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(e.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDebit ? Colors.red : Colors.green,
                            ),
                          ),
                          Text(
                            'બાકી: ${Formatters.formatCurrency(e.balanceAfter)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ઇતિહાસ લાવવામાં ભૂલ')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddUdhar(BuildContext context, int customerId) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AmountSheet(
        title: 'ઉધાર રકમ',
        onSubmit: (value) => Navigator.pop(ctx, value),
      ),
    );

    if (amount == null || amount <= 0) return;
    final repo = ref.read(khataRepositoryProvider);
    try {
      await repo.addEntry(KhataEntry(
        customerId: customerId,
        dateTimeMillis: DateTime.now().millisecondsSinceEpoch,
        type: 'debit',
        amount: amount,
        note: 'મેન્યુઅલ ઉધાર',
        balanceAfter: 0,
      ));
      if (mounted) {
        ref.invalidate(customerBalanceProvider(customerId));
        ref.invalidate(customerEntriesProvider(customerId));
        ref.invalidate(customersWithBalanceProvider);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ભૂલ: $e')),
        );
      }
    }
  }

  Future<void> _showRecordPayment(BuildContext context, int customerId) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AmountSheet(
        title: 'ચુકવણી રકમ',
        onSubmit: (value) => Navigator.pop(ctx, value),
      ),
    );

    if (amount == null || amount <= 0) return;
    final repo = ref.read(khataRepositoryProvider);
    try {
      await repo.addEntry(KhataEntry(
        customerId: customerId,
        dateTimeMillis: DateTime.now().millisecondsSinceEpoch,
        type: 'credit',
        amount: amount,
        note: 'ચુકવણી',
        balanceAfter: 0,
      ));
      if (mounted) {
        ref.invalidate(customerBalanceProvider(customerId));
        ref.invalidate(customerEntriesProvider(customerId));
        ref.invalidate(customersWithBalanceProvider);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ભૂલ: $e')),
        );
      }
    }
  }
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.onSubmit,
  });

  final String title;
  final void Function(double value) onSubmit;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  double _amount = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title),
              const SizedBox(height: 8),
              Text(Formatters.formatCurrency(_amount)),
              const SizedBox(height: 8),
              Numpad(
                initialValue: _amount > 0 ? _amount.toString() : '',
                onChanged: (v) =>
                    setState(() => _amount = double.tryParse(v) ?? 0),
                onSubmit: () => widget.onSubmit(_amount),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onSubmit(_amount),
                  child: const Text('ઓકે'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
