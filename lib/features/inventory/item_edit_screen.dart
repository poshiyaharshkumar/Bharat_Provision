import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/widgets/numpad.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/item.dart';
import '../../data/providers.dart';
import 'inventory_providers.dart';

class ItemEditScreen extends ConsumerStatefulWidget {
  const ItemEditScreen({super.key, this.itemId});

  final int? itemId;

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _barcodeController = TextEditingController();

  int? _categoryId;
  String _unit = AppStrings.unitPiece;
  bool _isActive = true;
  bool _loading = true;
  Item? _item;

  static const List<String> _units = [
    'નંગ',
    'કિલો',
    'ગ્રામ',
    'લીટર',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.itemId == null) {
      setState(() {
        _loading = false;
        _salePriceController.text = '0';
        _purchasePriceController.text = '0';
        _stockController.text = '0';
        _lowStockController.text = '0';
      });
      return;
    }
    final repo = await ref.read(itemRepositoryFutureProvider.future);
    final item = await repo.getById(widget.itemId!);
    if (item != null && mounted) {
      setState(() {
        _item = item;
        _nameController.text = item.nameGu;
        _salePriceController.text = item.salePrice.toString();
        _purchasePriceController.text = item.purchasePrice.toString();
        _stockController.text = item.currentStock.toString();
        _lowStockController.text = item.lowStockThreshold.toString();
        _barcodeController.text = item.barcode ?? '';
        _categoryId = item.categoryId;
        _unit = item.unit;
        _isActive = item.isActive;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.fieldRequired)),
      );
      return;
    }

    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final stock = double.tryParse(_stockController.text) ?? 0;
    final lowStock = double.tryParse(_lowStockController.text) ?? 0;

    final repo = await ref.read(itemRepositoryFutureProvider.future);

    try {
      if (_item != null) {
        await repo.update(_item!.copyWith(
          nameGu: name,
          categoryId: _categoryId,
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          unit: _unit,
          salePrice: salePrice,
          purchasePrice: purchasePrice,
          currentStock: stock,
          lowStockThreshold: lowStock,
          isActive: _isActive,
        ));
      } else {
        await repo.insert(Item(
          nameGu: name,
          categoryId: _categoryId,
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          unit: _unit,
          salePrice: salePrice,
          purchasePrice: purchasePrice,
          currentStock: stock,
          lowStockThreshold: lowStock,
          isActive: _isActive,
        ));
      }
      ref.invalidate(itemListProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ઉત્પાદ સફળતાપૂર્વક સેવ થયું')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorGeneric} $e')),
        );
      }
    }
  }

  void _showNumpad(TextEditingController ctrl, String label) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(ctx).width,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  NumpadTextField(
                    controller: ctrl,
                    allowDecimal: true,
                    decoration: const InputDecoration(),
                  ),
                  const SizedBox(height: 16),
                  NumpadWidget(
                    controller: ctrl,
                    allowDecimal: true,
                    onSubmit: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId != null ? AppStrings.editItem : AppStrings.addItem),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.itemName,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: AppStrings.barcode,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: AppStrings.category),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ...ref.watch(categoryListProvider).when(
                      data: (cats) => cats
                          .map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.nameGu),
                              ))
                          .toList(),
                      loading: () => [],
                      error: (e, st) => [],
                    ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: AppStrings.unit),
              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(AppStrings.sellPrice),
              subtitle: Text(_salePriceController.text),
              trailing: const Icon(Icons.edit),
              onTap: () => _showNumpad(_salePriceController, AppStrings.sellPrice),
            ),
            ListTile(
              title: Text(AppStrings.buyPrice),
              subtitle: Text(_purchasePriceController.text),
              trailing: const Icon(Icons.edit),
              onTap: () => _showNumpad(_purchasePriceController, AppStrings.buyPrice),
            ),
            ListTile(
              title: Text(AppStrings.currentStock),
              subtitle: Text(_stockController.text),
              trailing: const Icon(Icons.edit),
              onTap: () => _showNumpad(_stockController, AppStrings.currentStock),
            ),
            ListTile(
              title: Text(AppStrings.lowStockThreshold),
              subtitle: Text(_lowStockController.text),
              trailing: const Icon(Icons.edit),
              onTap: () => _showNumpad(_lowStockController, AppStrings.lowStockThreshold),
            ),
            SwitchListTile(
              title: const Text(AppStrings.activeToggle),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: AppStrings.saveButton,
              icon: Icons.save,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
