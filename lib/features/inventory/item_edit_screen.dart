import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/numpad.dart';
import '../../data/models/item.dart';
import '../../data/providers.dart';

class ItemEditScreen extends ConsumerStatefulWidget {
  const ItemEditScreen({super.key, this.existing});

  final Item? existing;

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();

  double _salePrice = 0;
  double _purchasePrice = 0;
  double _lowStockThreshold = 0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.nameGu;
      _unitController.text = existing.unit ?? '';
      _salePrice = existing.salePrice;
      _purchasePrice = existing.purchasePrice ?? 0;
      _lowStockThreshold = existing.lowStockThreshold;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final repo = ref.read(itemRepositoryProvider);

    final base = Item(
      id: widget.existing?.id,
      nameGu: _nameController.text.trim(),
      categoryId: null,
      barcode: null,
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      salePrice: _salePrice,
      purchasePrice: _purchasePrice == 0 ? null : _purchasePrice,
      currentStock: widget.existing?.currentStock ?? 0,
      lowStockThreshold: _lowStockThreshold,
      isActive: true,
    );

    try {
      if (widget.existing == null) {
        await repo.insert(base);
      } else {
        await repo.update(base);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('વસ્તુ સાચવવામાં ભૂલ: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.existing == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('વસ્તુ કાઢી નાખો'),
        content: const Text(
          'શું તમે ખરેખર આ વસ્તુ કાઢી નાખવા માંગો છો? આ ક્રિયા પૂર્વવત્ કરી શકાશે નહીં.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('રદ કરો'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('કાઢી નાખો'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(itemRepositoryProvider).delete(widget.existing!.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('કાઢવામાં ભૂલ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'નવી વસ્તુ ઉમેરો' : 'વસ્તુમાં ફેરફાર કરો'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'વસ્તુનું નામ (ગુજરાતી)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'નામ જરૂરી છે';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'એકમ (જેમ કે પીસ, કિલો)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('વેચાણ ભાવ (₹): $_salePrice'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 220,
                      child: Numpad(
                        initialValue: _salePrice == 0 ? '' : '$_salePrice',
                        onChanged: (value) {
                          setState(() {
                            _salePrice = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('ખરીદી ભાવ (₹): $_purchasePrice'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 220,
                      child: Numpad(
                        initialValue: _purchasePrice == 0 ? '' : '$_purchasePrice',
                        onChanged: (value) {
                          setState(() {
                            _purchasePrice = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('લો સ્ટોક એલર્ટ માત્રા: $_lowStockThreshold'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 220,
                      child: Numpad(
                        initialValue:
                            _lowStockThreshold == 0 ? '' : '$_lowStockThreshold',
                        onChanged: (value) {
                          setState(() {
                            _lowStockThreshold = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('સાચવો'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

