import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/numpad.dart';
import '../../data/models/bill_item.dart';
import '../../data/providers.dart';
import 'billing_providers.dart';
import 'cart_state.dart';
import 'payment_dialog.dart';

class BillingHomeScreen extends ConsumerStatefulWidget {
  const BillingHomeScreen({super.key});

  @override
  ConsumerState<BillingHomeScreen> createState() => _BillingHomeScreenState();
}

class _BillingHomeScreenState extends ConsumerState<BillingHomeScreen> {
  String _search = '';

  Future<void> _saveBill() async {
    final cart = ref.read(cartProvider);
    if (cart.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('પહેલા વસ્તુઓ ઉમેરો.')),
      );
      return;
    }

    final total = cart.totalAmount;
    showPaymentDialog(
      context,
      amountDue: total,
      onConfirm: (paidAmount, paymentMode) async {
        final billRepo = ref.read(billRepositoryProvider);
        final billItems = cart.lines
            .map(
              (l) => BillItem(
                billId: 0,
                itemId: l.itemId,
                quantity: l.quantity,
                unitPrice: l.unitPrice,
                lineTotal: l.lineTotal,
              ),
            )
            .toList();

        try {
          await billRepo.createBillWithStockAndKhata(
            billItems: billItems,
            discountAmount: cart.discountAmount,
            paidAmount: paidAmount,
            paymentMode: paymentMode,
            customerId: null,
            createdByUserId: null,
          );
          ref.read(cartProvider.notifier).clear();
          ref.invalidate(itemsListProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('બીલ સાચવ્યું.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ભૂલ: $e')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final asyncItems = ref.watch(itemsListProvider(_search));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'વસ્તુ શોધો અથવા ટૅપ કરો...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'વસ્તુઓ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: asyncItems.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return const Center(
                                child: Text('પહેલા સ્ટોકમાં વસ્તુઓ ઉમેરો.'),
                              );
                            }
                            return ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  title: Text(item.nameGu),
                                  subtitle: Text(
                                    Formatters.formatCurrency(item.salePrice),
                                  ),
                                  trailing: const Icon(Icons.add_circle),
                                  onTap: () {
                                    ref.read(cartProvider.notifier).addItem(item);
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => Center(
                            child: Text('ભૂલ: $e'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'કાર્ટ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: cart.lines.isEmpty
                            ? const Center(
                                child: Text('અહીં વસ્તુઓ દેખાશે.'),
                              )
                            : ListView.builder(
                                itemCount: cart.lines.length,
                                itemBuilder: (context, index) {
                                  final line = cart.lines[index];
                                  return ListTile(
                                    title: Text(line.itemName),
                                    subtitle: Text(
                                      '${line.quantity} x ${Formatters.formatCurrency(line.unitPrice)} = ${Formatters.formatCurrency(line.lineTotal)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            var q = line.quantity;
                                            showModalBottomSheet<void>(
                                              context: context,
                                              builder: (ctx) => Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${line.itemName} - માત્રા',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Numpad(
                                                      initialValue: q.toString(),
                                                      onChanged: (v) {
                                                        final parsed =
                                                            double.tryParse(v);
                                                        if (parsed != null &&
                                                            parsed > 0) {
                                                          q = parsed;
                                                          ref
                                                              .read(cartProvider
                                                                  .notifier)
                                                              .updateQuantity(
                                                                  index, q);
                                                        }
                                                      },
                                                      onSubmit: () =>
                                                          Navigator.pop(ctx),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle),
                                          onPressed: () {
                                            ref
                                                .read(cartProvider.notifier)
                                                .removeAt(index);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (!cart.lines.isEmpty) ...[
                        const Divider(),
                        ListTile(
                          title: const Text('સબટોટલ'),
                          trailing: Text(
                            Formatters.formatCurrency(cart.subtotal),
                          ),
                        ),
                        ListTile(
                          title: const Text('ડિસ્કાઉન્ટ (₹)'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Formatters.formatCurrency(cart.discountAmount),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    builder: (ctx) => Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('ડિસ્કાઉન્ટ રકમ દાખલ કરો'),
                                          const SizedBox(height: 8),
                                          Numpad(
                                            initialValue: cart.discountAmount > 0
                                                ? cart.discountAmount.toString()
                                                : '',
                                            onChanged: (v) {
                                              ref
                                                  .read(cartProvider.notifier)
                                                  .setDiscount(
                                                      double.tryParse(v) ?? 0);
                                            },
                                            onSubmit: () =>
                                                Navigator.pop(ctx),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          title: const Text('કુલ'),
                          trailing: Text(
                            Formatters.formatCurrency(cart.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _saveBill,
                              icon: const Icon(Icons.save),
                              label: const Text('બચાવો અને બીલ પ્રિન્ટ કરો'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
