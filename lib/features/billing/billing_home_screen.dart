import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart' as strings;
import '../../core/utils/currency_format.dart';
import '../../core/utils/weight_calculator.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/product_provider.dart';
import 'billing_providers.dart';

/// Smart Billing screen (P04) – multi-tab, auto-weight, customer + payment flow.
class BillingHomeScreen extends ConsumerStatefulWidget {
  const BillingHomeScreen({super.key});

  @override
  ConsumerState<BillingHomeScreen> createState() => _BillingHomeScreenState();
}

class _BillingHomeScreenState extends ConsumerState<BillingHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isDesktopLayout {
    final size = MediaQuery.of(context).size;
    return size.width > 700;
  }

  @override
  Widget build(BuildContext context) {
    final tabsState = ref.watch(billingTabsProvider);

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: _ProductPanel(
            searchController: _searchController,
            onProductSelected: (product) => _openEntryDialog(product),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _BillPanel(
            tabsState: tabsState,
            onTabSelected: (index) =>
                ref.read(billingTabsProvider.notifier).switchToTab(index),
            onClearCurrent: () => _confirmClearCurrentTab(),
          ),
        ),
      ],
    );

    if (!_isDesktopLayout) {
      content = Column(
        children: [
          Expanded(
            flex: 2,
            child: _ProductPanel(
              searchController: _searchController,
              onProductSelected: (product) => _openEntryDialog(product),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 3,
            child: _BillPanel(
              tabsState: tabsState,
              onTabSelected: (index) =>
                  ref.read(billingTabsProvider.notifier).switchToTab(index),
              onClearCurrent: () => _confirmClearCurrentTab(),
            ),
          ),
        ],
      );
    }

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {
        if (event is! RawKeyDownEvent) return;
        final isCtrlPressed =
            event.isControlPressed || event.data.isModifierPressed(ModifierKey.controlModifier);
        if (!isCtrlPressed) return;
        final keyLabel = event.logicalKey.keyLabel;
        final index = switch (keyLabel) {
          '1' => 0,
          '2' => 1,
          '3' => 2,
          '4' => 3,
          '5' => 4,
          _ => -1,
        };
        if (index >= 0) {
          ref.read(billingTabsProvider.notifier).switchToTab(index);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(strings.AppStrings.billingTitle),
        ),
        body: content,
      ),
    );
  }

  Future<void> _openEntryDialog(Product product) async {
    final notifier = ref.read(billingTabsProvider.notifier);
    double amountPaid = product.sellPrice;
    double weightGrams = 1000;
    String mode = 'amount'; // 'amount' | 'weight'

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            double? calculatedWeight;
            double? calculatedAmount;

            if (mode == 'amount') {
              calculatedWeight = WeightCalculator.calculateWeightFromAmount(
                amountPaid: amountPaid,
                sellPricePerKg: product.sellPrice,
              );
            } else {
              calculatedAmount = WeightCalculator.calculateAmountFromWeight(
                weightGrams: weightGrams,
                sellPricePerKg: product.sellPrice,
              );
            }

            return AlertDialog(
              title: Text(product.nameGujarati),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('₹ રૂપિયાથી'),
                        selected: mode == 'amount',
                        onSelected: (_) => setState(() => mode = 'amount'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('⚖ વજનથી'),
                        selected: mode == 'weight',
                        onSelected: (_) => setState(() => mode = 'weight'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (mode == 'amount') ...[
                    TextField(
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '₹ રકમ દાખલ કરો',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setState(() {
                            amountPaid = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (calculatedWeight != null)
                      Text(
                        'આપો: ${WeightCalculator.formatWeight(calculatedWeight)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                  ] else ...[
                    TextField(
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'ગ્રામમાં વજન દાખલ કરો',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setState(() {
                            weightGrams = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (calculatedAmount != null)
                      Text(
                        'રકમ: ${formatCurrency(calculatedAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(strings.AppStrings.cancelButton),
                ),
                ElevatedButton(
                  onPressed: () {
                    double finalAmount;
                    double finalQty;
                    if (mode == 'amount') {
                      final weight = WeightCalculator.calculateWeightFromAmount(
                        amountPaid: amountPaid,
                        sellPricePerKg: product.sellPrice,
                      );
                      finalAmount = amountPaid;
                      finalQty = weight;
                    } else {
                      final amount = WeightCalculator.calculateAmountFromWeight(
                        weightGrams: weightGrams,
                        sellPricePerKg: product.sellPrice,
                      );
                      finalAmount = amount;
                      finalQty = weightGrams;
                    }

                    notifier.addLineToActive(
                      BillLine(
                        product: product,
                        qtyGrams: finalQty,
                        amount: finalAmount,
                      ),
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(strings.AppStrings.addButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmClearCurrentTab() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ટેબ સાફ કરો?'),
        content: const Text('હાલનો બિલ ટેબ પૂરો ખાલી થશે. ખાતરી છે?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(strings.AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(strings.AppStrings.clearButton),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(billingTabsProvider.notifier).clearActive();
    }
  }
}

class _ProductPanel extends ConsumerWidget {
  const _ProductPanel({
    required this.searchController,
    required this.onProductSelected,
  });

  final TextEditingController searchController;
  final void Function(Product product) onProductSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: strings.AppStrings.searchHintProducts,
            ),
            onChanged: (value) {
              if (value.trim().isEmpty) {
                ref.read(productProvider.notifier).loadAllProducts();
              } else {
                ref.read(productProvider.notifier).searchProducts(value);
              }
            },
          ),
        ),
        Expanded(
          child: state.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Text(strings.AppStrings.noProductsFound),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2),
                    ),
                    title: Text(p.nameGujarati),
                    subtitle: Text(
                      '₹${p.sellPrice.toStringAsFixed(2)} • ${p.stockQty.toStringAsFixed(0)}',
                    ),
                    onTap: () => onProductSelected(p),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('${strings.AppStrings.errorGeneric} $e')),
          ),
        ),
      ],
    );
  }
}

class _BillPanel extends ConsumerWidget {
  const _BillPanel({
    required this.tabsState,
    required this.onTabSelected,
    required this.onClearCurrent,
  });

  final BillingTabsState tabsState;
  final void Function(int index) onTabSelected;
  final VoidCallback onClearCurrent;

  Color _tabColor(BillDraft draft, bool isActive) {
    if (draft.isEmpty) return Colors.grey.shade400;
    if (isActive) return Colors.green.shade700;
    return Colors.green.shade400;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = tabsState.activeDraft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: List.generate(5, (index) {
              final d = tabsState.drafts[index];
              final isActive = index == tabsState.activeIndex;
              final itemCount = d.lines.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Bill-${index + 1}'),
                      if (itemCount > 0) ...[
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.white,
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: isActive,
                  selectedColor: _tabColor(d, true),
                  backgroundColor: _tabColor(d, false),
                  labelStyle: const TextStyle(color: Colors.white),
                  onSelected: (_) => onTabSelected(index),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: draft.lines.length,
            itemBuilder: (ctx, i) {
              final line = draft.lines[i];
              return ListTile(
                title: Text(line.product.nameGujarati),
                subtitle: Text(
                  '${WeightCalculator.formatWeight(line.qtyGrams)} = ${formatCurrency(line.amount)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () =>
                      ref.read(billingTabsProvider.notifier).removeLineFromActive(i),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(formatCurrency(draft.subtotal)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: () => _showDiscountDialog(context, ref, draft),
                      child: const Text('Discount'),
                    ),
                  ),
                  const Spacer(),
                  Text(formatCurrency(-draft.discountAmount)),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    formatCurrency(draft.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: draft.lines.isEmpty
                          ? null
                          : () {
                              // Payment + save flow will be wired in next step.
                            },
                      icon: const Icon(Icons.save),
                      label: const Text('બિલ બનાવો'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: draft.isEmpty ? null : onClearCurrent,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: 'ટેબ ક્લિયર',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDiscountDialog(
    BuildContext context,
    WidgetRef ref,
    BillDraft draft,
  ) async {
    final controller = TextEditingController(
      text: draft.discountAmount.toStringAsFixed(2),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ડિસ્કાઉન્ટ'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: '₹ રકમ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(strings.AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(strings.AppStrings.saveButton),
          ),
        ],
      ),
    );
    if (ok == true) {
      final value = double.tryParse(controller.text) ?? 0;
      ref.read(billingTabsProvider.notifier).setDiscountForActive(value);
    }
  }
}

