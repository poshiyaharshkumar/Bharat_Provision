import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import 'item_edit_screen.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  const ItemListScreen({super.key});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  String _search = '';
  bool _lowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(itemsListProvider(_search));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'વસ્તુ શોધો...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('લો સ્ટોક'),
                selected: _lowStockOnly,
                onSelected: (value) {
                  setState(() {
                    _lowStockOnly = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: asyncItems.when(
            data: (items) {
              final filtered =
                  _lowStockOnly ? items.where((e) => e.isLowStock).toList() : items;
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('અહીં હજુ કોઈ વસ્તુ ઉમેરાયેલ નથી.'),
                );
              }
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final stock = item.currentStock;
                  final isLow = item.isLowStock;
                  final color =
                      isLow ? Colors.red.shade400 : Colors.green.shade600;

                  return ListTile(
                    title: Text(item.nameGu),
                    subtitle: Text(
                      'સ્ટોક: $stock | ભાવ: ${Formatters.formatCurrency(item.salePrice)}',
                    ),
                    trailing: Icon(
                      Icons.circle,
                      color: color,
                      size: 16,
                    ),
                    onTap: () async {
                      final reloaded = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ItemEditScreen(existing: item),
                        ),
                      );
                      if (reloaded == true && mounted) {
                        setState(() {});
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Text('ડેટા લાવવામાં ભૂલ: $error'),
            ),
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
                    builder: (_) => const ItemEditScreen(),
                  ),
                );
                if (created == true && mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('નવી વસ્તુ'),
            ),
          ),
        ),
      ],
    );
  }
}

