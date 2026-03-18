import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/return_repository.dart';
import '../../shared/models/bill_item_model.dart';
import '../../shared/models/bill_model.dart';
import '../../shared/models/product_model.dart';
import 'returns_providers.dart';

class ReplaceScreen extends ConsumerStatefulWidget {
  const ReplaceScreen({super.key});

  @override
  ConsumerState<ReplaceScreen> createState() => _ReplaceScreenState();
}

class _ReplaceScreenState extends ConsumerState<ReplaceScreen> {
  final _searchCtrl = TextEditingController();
  List<Bill> _searchResults = [];
  Bill? _selectedBill;
  List<BillItem> _billItems = [];
  BillItem? _selectedReturnItem;
  final _returnQtyCtrl = TextEditingController();

  List<Product> _productSearchResults = [];
  Product? _selectedReplacementProduct;
  final _replacementQtyCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _returnQtyCtrl.dispose();
    _replacementQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchBills() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
      _selectedBill = null;
      _billItems = [];
      _selectedReturnItem = null;
      _productSearchResults = [];
      _selectedReplacementProduct = null;
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
      _selectedReturnItem = null;
      _productSearchResults = [];
      _selectedReplacementProduct = null;
    });
    try {
      final repo = ref.read(returnRepositoryProvider);
      final items = await repo.getBillItems(billId);
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

  Future<void> _searchProducts(String query) async {
    final repo = ref.read(returnRepositoryProvider);
    final results = await repo.getProducts(query: query);
    setState(() {
      _productSearchResults = results;
    });
  }

  double get _returnValue {
    if (_selectedReturnItem == null) return 0;
    final qty = double.tryParse(_returnQtyCtrl.text) ?? 0;
    return qty * (_selectedReturnItem!.sellPriceSnapshot ?? 0);
  }

  double get _replacementQtyCalculated {
    if (_selectedReturnItem == null || _selectedReplacementProduct == null) {
      return 0;
    }
    if (_selectedReplacementProduct!.sellPrice <= 0) return 0;
    final returnValue = _returnValue;
    return (returnValue / _selectedReplacementProduct!.sellPrice) * 1000;
  }

  double get _replacementQtyGiven {
    return double.tryParse(_replacementQtyCtrl.text) ??
        _replacementQtyCalculated;
  }

  double get _priceDifference {
    final returnValue = _returnValue;
    final replacementCost =
        (_replacementQtyGiven / 1000) *
        (_selectedReplacementProduct?.sellPrice ?? 0);
    return replacementCost - returnValue;
  }

  Future<void> _confirmReplace() async {
    if (_selectedBill == null ||
        _selectedReturnItem == null ||
        _selectedReplacementProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('સૌ પ્રથમ બિલ, પાછું અને બદલોપટા પસંદ કરો'),
        ),
      );
      return;
    }

    final qtyReturned = double.tryParse(_returnQtyCtrl.text) ?? 0;
    if (qtyReturned <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('મહેરબાની કરીને પાછું માટે માન્ય માત્રા દાખલ કરો'),
        ),
      );
      return;
    }

    final replacementQtyGiven =
        double.tryParse(_replacementQtyCtrl.text) ?? _replacementQtyCalculated;
    if (replacementQtyGiven <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('બદલી માટે માન્ય માત્રા દાખલ કરો')),
      );
      return;
    }

    final returnLine = ReturnLine(
      billItemId: _selectedReturnItem!.id!,
      productId: _selectedReturnItem!.productId,
      qtyReturned: qtyReturned,
      sellPriceSnapshot: _selectedReturnItem!.sellPriceSnapshot ?? 0,
    );

    final replacementInput = ReplacementInput(
      returnedProductId: _selectedReturnItem!.productId,
      returnedQty: qtyReturned,
      returnedPricePerKg: _selectedReturnItem!.sellPriceSnapshot ?? 0,
      replacementProductId: _selectedReplacementProduct!.id!,
      replacementPricePerKg: _selectedReplacementProduct!.sellPrice,
      replacementQtyGiven: replacementQtyGiven,
      replacementQtyCalculated: _replacementQtyCalculated,
      priceDifference: _priceDifference,
      differenceMode: ref.read(returnModeProvider),
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final diff = _priceDifference;
        final diffText = diff.abs() < 0.01
            ? 'કોઈ ભાવ ભેદ નથી'
            : diff > 0
            ? 'ગ્રાહક ₹${diff.toStringAsFixed(2)} વધુ ચૂકવીશે'
            : 'દુકાનદારે ₹${(-diff).toStringAsFixed(2)} પરત આપશે';

        return AlertDialog(
          title: const Text('બદલો પુષ્ટિકરણ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'પાછું: ${_selectedReturnItem!.productNameSnapshot} ${qtyReturned.toStringAsFixed(2)}g',
              ),
              Text(
                'બદલી: ${_selectedReplacementProduct!.nameGujarati} ${replacementQtyGiven.toStringAsFixed(2)}g',
              ),
              const SizedBox(height: 8),
              Text(diffText),
              const SizedBox(height: 8),
              const Text('પ્રગટાવવામાં આવશે વધુ ઉપાય'),
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

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(returnRepositoryProvider);
      await repo.createReplace(
        billId: _selectedBill!.id!,
        customerId: _selectedBill!.customerId,
        returnLine: returnLine,
        replacement: replacementInput,
        returnMode: ref.read(returnModeProvider),
        notes:
            'Replace: ${_selectedReturnItem!.productNameSnapshot} → ${_selectedReplacementProduct!.nameGujarati}',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('બદલી સફળતાપૂર્વક થઈ')));
      await _loadBillItems(_selectedBill!.id!);
      setState(() {
        _selectedReplacementProduct = null;
        _productSearchResults = [];
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
      appBar: AppBar(title: const Text('બદલવું')),
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
            Expanded(
              child: _selectedBill == null
                  ? _buildSearchResults()
                  : _buildReplaceForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('બિલ શોધવા માટે ઉપર શોધ બાર ઉપયોગ કરો'));
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

  Widget _buildReplaceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('બિલ #: ${_selectedBill?.billNumber ?? ''}')),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedBill = null;
                  _billItems = [];
                  _selectedReturnItem = null;
                  _selectedReplacementProduct = null;
                });
              },
              child: const Text('પાછા'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('પાછું લેવારું આઇટમ પસંદ કરો'),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _billItems.length,
            itemBuilder: (context, index) {
              final item = _billItems[index];
              final isSelected = _selectedReturnItem?.id == item.id;
              return ListTile(
                title: Text(item.productNameSnapshot ?? ''),
                subtitle: Text('Qty: ${item.qty.toStringAsFixed(2)}'),
                trailing: isSelected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  setState(() {
                    _selectedReturnItem = item;
                    _returnQtyCtrl.text = item.qty.toStringAsFixed(2);
                  });
                },
              );
            },
          ),
        ),
        if (_selectedReturnItem != null) ...[
          const Divider(),
          Text(
            'પાછું ખરીદી મંજુર કરો: ${_selectedReturnItem!.productNameSnapshot}',
          ),
          TextField(
            controller: _returnQtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'પાછું લાખેલી માત્રા (g)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          const Text('બદલી માટે ઉત્પાદન પસંદ કરો'),
          TextField(
            decoration: const InputDecoration(
              labelText: 'સરફ કોર',
              hintText: 'ઉત્પાદન શોધો',
            ),
            onChanged: (v) => _searchProducts(v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _productSearchResults.length,
              itemBuilder: (context, index) {
                final prod = _productSearchResults[index];
                final selected = _selectedReplacementProduct?.id == prod.id;
                return ListTile(
                  title: Text(prod.nameGujarati),
                  subtitle: Text('₹${prod.sellPrice.toStringAsFixed(2)}/kg'),
                  trailing: selected ? const Icon(Icons.check_circle) : null,
                  onTap: () {
                    setState(() {
                      _selectedReplacementProduct = prod;
                      _replacementQtyCtrl.text = _replacementQtyCalculated
                          .toStringAsFixed(2);
                    });
                  },
                );
              },
            ),
          ),
          if (_selectedReplacementProduct != null) ...[
            const Divider(),
            Text(
              'બદલી મળતી માત્રા (ગ્રામ): ${_replacementQtyCalculated.toStringAsFixed(2)}',
            ),
            TextField(
              controller: _replacementQtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'બસ મળતી માત્રા (ગ્રામ)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ભાવ ફરક:'),
                Text(
                  _priceDifference.abs() < 0.01
                      ? '₹0.00'
                      : _priceDifference > 0
                      ? 'ગ્રાહક ₹${_priceDifference.toStringAsFixed(2)} વધુ આપે'
                      : 'દુકાનદારે ₹${(-_priceDifference).toStringAsFixed(2)} આપે',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('મોડ:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: ref.watch(returnModeProvider),
                  items: const [
                    DropdownMenuItem(value: 'cash_refund', child: Text('કેશ')),
                    DropdownMenuItem(
                      value: 'udhaar_credit',
                      child: Text('ઉધાર'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(returnModeProvider.notifier).state = v;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmReplace,
              child: const Text('બદલી પ્રક્રિયા કરો'),
            ),
          ],
        ],
      ],
    );
  }
}
