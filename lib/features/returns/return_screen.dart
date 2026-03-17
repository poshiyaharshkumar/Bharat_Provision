import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_format.dart';
import '../../data/repositories/return_repository.dart';
import '../../shared/models/bill_item_model.dart';
import '../../shared/models/bill_model.dart';
import 'returns_providers.dart';

class ReturnScreen extends ConsumerStatefulWidget {
  const ReturnScreen({super.key});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  final _searchCtrl = TextEditingController();
  List<Bill> _searchResults = [];
  Bill? _selectedBill;
  List<BillItem> _billItems = [];

  /// Map of billItemId -> return qty
  final Map<int, TextEditingController> _qtyControllers = {};

  /// Set of billItemId selected for return
  final Set<int> _selectedItemIds = {};

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _searchBills() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
      _selectedBill = null;
      _billItems = [];
      _selectedItemIds.clear();
    });
    try {
      final repo = ref.read(returnRepositoryProvider);
      final results = await repo.searchBills(_searchCtrl.text.trim());
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBillItems(int billId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _billItems = [];
      _selectedItemIds.clear();
      _qtyControllers.clear();
    });
    try {
      final repo = ref.read(returnRepositoryProvider);
      final items = await repo.getBillItems(billId);
      for (final item in items) {
        _qtyControllers[item.id!] = TextEditingController(
          text: item.qty.toStringAsFixed(2),
        );
      }
      setState(() {
        _billItems = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get _refundTotal {
    double total = 0;
    for (final item in _billItems) {
      if (!_selectedItemIds.contains(item.id)) continue;
      final qty = double.tryParse(_qtyControllers[item.id!]!.text) ?? 0;
      total += qty * (item.sellPriceSnapshot ?? 0);
    }
    return total;
  }

  Future<void> _confirmReturn() async {
    if (_selectedBill == null) return;
    final selectedLineIds = _selectedItemIds.toList();
    if (selectedLineIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કમ સે કમ એક આઇટમ પસંદ કરો')),
      );
      return;
    }

    final lines = <ReturnLine>[];
    for (final item in _billItems) {
      if (!_selectedItemIds.contains(item.id)) continue;
      final qty = double.tryParse(_qtyControllers[item.id!]!.text) ?? 0;
      if (qty <= 0) continue;
      final maxQty = item.qty;
      final finalQty = qty > maxQty ? maxQty : qty;
      lines.add(
        ReturnLine(
          billItemId: item.id!,
          productId: item.productId,
          qtyReturned: finalQty,
          sellPriceSnapshot: item.sellPriceSnapshot ?? 0,
        ),
      );
    }

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('માન્યતા માટે યોગ્ય આઇટમ અને માત્રા પસંદ કરો'),
        ),
      );
      return;
    }

    final mode = ref.read(returnModeProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('પાછું લેવાનું પ્રમાણિત કરો'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('બિલ #: ${_selectedBill!.billNumber}'),
              const SizedBox(height: 8),
              Text('મોટો રકમ: ${formatCurrency(_refundTotal)}'),
              Text(
                'રીફંડ મોડ: ${mode == 'cash_refund' ? 'કેશ રિફંડ' : 'ઉધાર ક્રેડિટ'}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('રદ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('સાચવો'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(returnRepositoryProvider);
      await repo.createReturn(
        billId: _selectedBill!.id!,
        customerId: _selectedBill!.customerId,
        lines: lines,
        returnMode: mode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('રિફંડ સફળતાપૂર્વક લેવામાં આવ્યું')),
      );
      await _loadBillItems(_selectedBill!.id!);
      setState(() {
        // clear selections
        _selectedItemIds.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('પાછું આપવું')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'બિલ નંબર અથવા ગ્રાહક નામ',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchBills(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: _searchBills,
                    child: const Text('શોધો'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            if (_isLoading) const LinearProgressIndicator(),
            if (_selectedBill == null)
              Expanded(child: _buildSearchResults())
            else
              Expanded(child: _buildBillDetail()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('બિલ શોધવા માટે ઉપર શોધ બારથી શરૂ કરો'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final bill = _searchResults[index];
        return ListTile(
          title: Text('બિલ #: ${bill.billNumber}'),
          subtitle: Text('ગ્રાહક: ${bill.customerNameSnapshot ?? '-'}'),
          trailing: Text(bill.paymentStatus ?? ''),
          onTap: () async {
            setState(() {
              _selectedBill = bill;
            });
            await _loadBillItems(bill.id!);
          },
        );
      },
    );
  }

  Widget _buildBillDetail() {
    if (_billItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('બિલ #: ${_selectedBill?.billNumber ?? ''}'),
          const SizedBox(height: 8),
          const Text('આ બિલ માટે કોઈ આઇટમ મળ્યાં નથી'),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _selectedBill = null),
            child: const Text('પાછા'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'બિલ #: ${_selectedBill?.billNumber ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _selectedBill = null;
                _billItems = [];
                _selectedItemIds.clear();
              }),
              child: const Text('પાછા'),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _billItems.length,
            itemBuilder: (context, index) {
              final item = _billItems[index];
              final alreadyReturned = item.isReturned;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productNameSnapshot ?? 'ઉત્પાદન',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: alreadyReturned
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (alreadyReturned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('પાછું આવ્યું'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Qty: ${item.qty.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '₹${(item.sellPriceSnapshot ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!alreadyReturned) ...[
                        Row(
                          children: [
                            Checkbox(
                              value: _selectedItemIds.contains(item.id),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedItemIds.add(item.id!);
                                  } else {
                                    _selectedItemIds.remove(item.id);
                                  }
                                });
                              },
                            ),
                            const Text('પાછું લેવારું'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _qtyControllers[item.id!],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'માત્રા (qty)',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedItemIds.contains(item.id))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'રીફંડ રકમ: ${formatCurrency((double.tryParse(_qtyControllers[item.id!]!.text) ?? 0) * (item.sellPriceSnapshot ?? 0))}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('રીફંડ મોડ:'),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: ref.watch(returnModeProvider),
              items: const [
                DropdownMenuItem(
                  value: 'cash_refund',
                  child: Text('કેશ રિફંડ'),
                ),
                DropdownMenuItem(
                  value: 'udhaar_credit',
                  child: Text('ઉધાર ક્રેડિટ'),
                ),
              ],
              onChanged: (v) {
                if (v != null) ref.read(returnModeProvider.notifier).state = v;
              },
            ),
            const Spacer(),
            Text('ટોટલ: ${formatCurrency(_refundTotal)}'),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmReturn,
          child: const Text('રિફંડ પ્રોસેસ કરો'),
        ),
      ],
    );
  }
}
