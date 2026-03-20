import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'; // TODO: Add to pubspec.yaml

import '../../core/constants/app_strings.dart' as strings;
import '../../core/errors/error_handler.dart';
import '../../core/errors/error_types.dart';
import '../../shared/widgets/errors/error_dialogue.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/weight_calculator.dart';
import '../../data/models/customer.dart';
import '../../data/models/item.dart';
import '../../data/providers.dart';
import '../../data/services/bill_service.dart';
import '../../data/services/bill_service_provider.dart';
import '../../routing/app_router.dart';
import 'billing_providers.dart';
import '../../core/services/notification_service.dart';
import '../../features/stock/stock_providers.dart';

/// Simplified single-screen billing - Create bills and print them.
class BillingHomeScreen extends ConsumerStatefulWidget {
  const BillingHomeScreen({super.key});

  @override
  ConsumerState<BillingHomeScreen> createState() => _BillingHomeScreenState();
}

class _BillingHomeScreenState extends ConsumerState<BillingHomeScreen> {
  final _searchController = TextEditingController();
  final List<BillLineItem> _billLines = [];
  double _discount = 0;
  String? _bannerMessage;

  int? _selectedCustomerId;
  String? _selectedCustomerName;
  final List<String> _oldCustomerNames = [];

  @override
  void initState() {
    super.initState();
    // Load all items when screen loads (from inventory items table)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingSearchProvider.notifier).state = '';
      ref.invalidate(billingItemsProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _subtotal => _billLines.fold(0, (sum, line) => sum + line.amount);
  double get _total => _subtotal - _discount;

  Future<void> _saveBill() async {
    if (_billLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('બિલ ખાલી છે. પ્રથમ વસ્તુ ઉમેરો.')),
      );
      return;
    }

    final billItems = _billLines
        .where((l) => l.item.id != null)
        .map(
          (l) => BillItemInput(
            itemId: l.item.id!,
            quantity: l.qtyGrams,
            unitPrice: l.item.salePrice,
          ),
        )
        .toList();

    if (billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('બિલ સંગ્રહ માટે માન્ય વસ્તુઓ જરૂરી છે.')),
      );
      return;
    }

    final customerName = _selectedCustomerName ?? 'Walk-in Customer';

    try {
      final service = await ref.read(billServiceProvider.future);
      await service.saveBill(
        customerId: _selectedCustomerId,
        customerName: customerName,
        items: billItems,
        discountAmount: _discount,
        paidAmount: _total,
        paymentMode: 'cash',
        userId: 1,
      );

      setState(() {
        _billLines.clear();
        _discount = 0;
        _selectedCustomerId = null;
        _selectedCustomerName = null;
        _oldCustomerNames.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('બિલ સફળતાપૂર્વક સાચવાયો.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('બીલ સાચવવામાં ત્રુટી: $e')));
    }

    // After save, still display stock alerts for any low/out-of-stock items.
    final productIds = billItems.map((i) => i.itemId).whereType<int>().toList();
    final stockRepo = ref.read(stockRepositoryProvider);
    final alertResult = await stockRepo.checkStockAlerts(productIds);
    final userRole = await _getCurrentUserRole();

    if (alertResult.lowStock.isNotEmpty || alertResult.outOfStock.isNotEmpty) {
      final names = [
        ...alertResult.lowStock.map((p) => p.nameGujarati),
        ...alertResult.outOfStock.map((p) => p.nameGujarati),
      ].join(', ');
      if (userRole == 'employee') {
        setState(() {
          _bannerMessage = 'સ્ટોક ઓછો/ખૂટ્યો: $names';
        });
      } else {
        setState(() {
          _bannerMessage = 'સ્ટોક ઓછો/ખૂટ્યો: $names';
        });
        for (final p in alertResult.lowStock) {
          await NotificationService.instance.showLowStockAlert(
            productName: p.nameGujarati,
            qty: p.stockQty,
          );
        }
        for (final p in alertResult.outOfStock) {
          await NotificationService.instance.showOutOfStockAlert(
            productName: p.nameGujarati,
          );
        }
      }
    } else {
      setState(() {
        _bannerMessage = null;
      });
    }
  }

  Future<String> _getCurrentUserRole() async {
    // Replace with actual user role fetch logic
    // For demo, return 'admin'
    return 'admin';
  }

  Future<void> _setSelectedCustomer(int? id, String? name) async {
    if (_selectedCustomerName != null &&
        _selectedCustomerName!.isNotEmpty &&
        _selectedCustomerName != name) {
      _oldCustomerNames.add(_selectedCustomerName!);
    }
    setState(() {
      _selectedCustomerId = id;
      _selectedCustomerName = name;
    });
  }

  Future<void> _selectExistingCustomer() async {
    try {
      final repo = await ref.read(customerRepositoryFutureProvider.future);
      final customers = await repo.getAll();

      final selected = await showDialog<Customer?>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('ઘરે થી ગ્રાહક પસંદ કરો'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('કોઈ નહિં (Walk-in)'),
            ),
            ...customers.map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(c),
                child: Text(
                  '${c.name}${c.phone != null ? ' (${c.phone})' : ''}',
                ),
              ),
            ),
          ],
        ),
      );

      if (selected != null) {
        await _setSelectedCustomer(selected.id, selected.name);
      } else {
        await _setSelectedCustomer(null, 'Walk-in Customer');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ગ્રાહક લોડ કરવામાં ત્રુટી: $e')));
    }
  }

  Future<void> _addNewCustomer() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('નવો ગ્રાહક ઉમેરો'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'ગ્રાહકનું નામ'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'ફોન નંબર (ಐચ્છિક)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('રદ કરો'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('જમણ કરી'),
          ),
        ],
      ),
    );

    if (success != true) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ગ્રાહકનું નામ જરૂરી છે')));
      return;
    }

    try {
      final repo = await ref.read(customerRepositoryFutureProvider.future);
      final newId = await repo.insert(
        Customer(name: name, phone: phone.isEmpty ? null : phone),
      );
      await _setSelectedCustomer(newId, name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('નવો ગ્રાહક સિસ્ટમમાં ઉમેરાયો')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ગ્રાહક સંગ્રહમાં ત્રુટી: $e')));
    }
  }

  void _addProductToBill(Item item) async {
    if (item.currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('સ્ટોક ઉપલબ્ધ નથી')), // Gujarati message
      );
      return;
    }
    double amountPaid = item.salePrice;
    double weightGrams = 1000;
    String mode = 'amount';
    bool itemAdded = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            double? calculatedWeight;
            double? calculatedAmount;

            if (mode == 'amount') {
              calculatedWeight = WeightCalculator.calculateWeightFromAmount(
                amountPaid: amountPaid,
                sellPricePerKg: item.salePrice,
              );
            } else {
              calculatedAmount = WeightCalculator.calculateAmountFromWeight(
                weightGrams: weightGrams,
                sellPricePerKg: item.salePrice,
              );
            }

            return AlertDialog(
              title: Text(item.nameGu),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('₹ રૂપિયાથી'),
                        selected: mode == 'amount',
                        onSelected: (_) =>
                            setDialogState(() => mode = 'amount'),
                      ),
                      ChoiceChip(
                        label: const Text('⚖ વજનથી'),
                        selected: mode == 'weight',
                        onSelected: (_) =>
                            setDialogState(() => mode = 'weight'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (mode == 'amount') ...[
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '₹ રકમ દાખલ કરો',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setDialogState(() => amountPaid = parsed);
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'ગ્રામમાં વજન દાખલ કરો',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setDialogState(() => weightGrams = parsed);
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
                    double finalAmount, finalQty;
                    if (mode == 'amount') {
                      finalQty = WeightCalculator.calculateWeightFromAmount(
                        amountPaid: amountPaid,
                        sellPricePerKg: item.salePrice,
                      );
                      finalAmount = amountPaid;
                    } else {
                      finalAmount = WeightCalculator.calculateAmountFromWeight(
                        weightGrams: weightGrams,
                        sellPricePerKg: item.salePrice,
                      );
                      finalQty = weightGrams;
                    }
                    _billLines.add(
                      BillLineItem(
                        item: item,
                        qtyGrams: finalQty,
                        amount: finalAmount,
                      ),
                    );
                    itemAdded = true;
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

    // Trigger parent widget rebuild after dialog closes
    if (itemAdded && mounted) {
      setState(() {});
    }
  }

  void _removeLine(int index) {
    setState(() => _billLines.removeAt(index));
  }

  void _setDiscount() async {
    final controller = TextEditingController(
      text: _discount.toStringAsFixed(2),
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ડિસ્કાઉન્ટ સેટ કરો'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: '₹ રકમ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(strings.AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _discount = double.tryParse(controller.text) ?? 0);
              Navigator.of(ctx).pop();
            },
            child: const Text(strings.AppStrings.saveButton),
          ),
        ],
      ),
    );
  }

  Future<void> _printBill() async {
    if (_billLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('બિલ ખાલી છે. કૃપया આઇટમ ઉમેરો.')),
      );
      return;
    }
    try {
      final billText = _generateBillText();
      // TODO: Integrate with print_bluetooth_thermal package
      // For now, show bill in a dialog
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('બિલ ટેક્સ્ટ'),
          content: SingleChildScrollView(
            child: Text(
              billText,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('બંધ કરો'),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('બિલ તૈયાર! (Bluetooth print pending integration)'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ભૂલ: $e')));
    }
  }

  String _generateBillText() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('===============================');
    buffer.writeln('            બિલ');
    buffer.writeln('===============================\n');
    buffer.writeln('Customer: ${_selectedCustomerName ?? 'Walk-in Customer'}');
    if (_oldCustomerNames.isNotEmpty) {
      buffer.writeln('Previous customers: ${_oldCustomerNames.join(', ')}');
    }
    buffer.writeln('');
    for (var line in _billLines) {
      buffer.writeln(line.item.nameGu);
      buffer.writeln(
        '  ${WeightCalculator.formatWeight(line.qtyGrams)}  ${formatCurrency(line.amount)}',
      );
    }
    buffer.writeln('\n-------------------------------');
    buffer.writeln('કુલ: ${formatCurrency(_subtotal)}');
    if (_discount > 0) buffer.writeln('ડિસ્ક: -${formatCurrency(_discount)}');
    buffer.writeln('-------------------------------');
    buffer.writeln('દેય: ${formatCurrency(_total)}');
    buffer.writeln('===============================');
    buffer.writeln('ધન્યવાદ!');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Use desktop (2-column) layout for most desktop widths; otherwise the
    // bill panel moves below the product list and looks "missing".
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text(strings.AppStrings.billingTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBill,
            tooltip: 'બિલ સાચવો',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printBill,
            tooltip: 'બિલ છાપો',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'returns') {
                Navigator.of(context).pushNamed(AppRouter.returnsNew);
              } else if (value == 'replace') {
                Navigator.of(context).pushNamed(AppRouter.returnsReplace);
              } else if (value == 'history') {
                Navigator.of(context).pushNamed(AppRouter.returnsHistory);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'returns', child: Text('પાછું આપવું')),
              const PopupMenuItem(value: 'replace', child: Text('બદલવું')),
              const PopupMenuItem(
                value: 'history',
                child: Text('પાછું આપવાનો ઇતિહાસ'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_bannerMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bannerMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildProductPanel()),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: _buildBillPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(flex: 2, child: _buildProductPanel()),
        const Divider(height: 1),
        Expanded(flex: 3, child: _buildBillPanel()),
      ],
    );
  }

  Widget _buildProductPanel() {
    final state = ref.watch(billingItemsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[50],
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ઉત્પાદ શોધો...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              ref.read(billingSearchProvider.notifier).state = value;
            },
          ),
        ),
        Expanded(
          child: state.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'કોઈ ઉત્પાદન મળ્યું નહીં',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isEmpty
                            ? 'ઉત્પાદન ઉમેરવા માટે ઇન્વેન્ટરીમાં જાઓ'
                            : '"${_searchController.text}" માટે કોઈ ઉત્પાદન નથી',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('પુનરાવર્તમાન કરો'),
                        onPressed: () {
                          ref.read(billingSearchProvider.notifier).state = '';
                          _searchController.clear();
                          ref.invalidate(billingItemsProvider);
                        },
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: Text(item.nameGu),
                    subtitle: Text('₹${item.salePrice.toStringAsFixed(2)}'),
                    onTap: () => _addProductToBill(item),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) {
              final appError = e is AppError
                  ? e
                  : ErrorHandler.handle(e, st, context: 'BillingHomeScreen');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ErrorDialogue.showSnackbar(
                  context,
                  message: appError.userMessage,
                  code: appError.code,
                  type: ErrorDialogueType.error,
                );
              });
              return Center(
                child: Text(
                  appError.userMessage,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'હાલનો બિલ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ગ્રાહક: ${_selectedCustomerName ?? 'Walk-in Customer'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectExistingCustomer,
                    child: const Text('પહેલાં ગ્રાહકો'),
                  ),
                  TextButton(
                    onPressed: _addNewCustomer,
                    child: const Text('નવો ગ્રાહક'),
                  ),
                ],
              ),
              if (_oldCustomerNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'પાછલા: ${_oldCustomerNames.join(', ')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (_billLines.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'બિલ ખાલી છે',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ડાબી બાજુથી ઉત્પાદન પસંદ કરો',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _billLines.length,
              itemBuilder: (ctx, i) {
                final line = _billLines[i];
                return Dismissible(
                  key: Key(i.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeLine(i),
                  child: ListTile(
                    title: Text(line.item.nameGu),
                    subtitle: Text(
                      WeightCalculator.formatWeight(line.qtyGrams),
                    ),
                    trailing: Text(
                      formatCurrency(line.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('કુલ:'),
                  Text(
                    formatCurrency(_subtotal),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _setDiscount,
                    child: const Text(
                      'ડિસ્કાઉન્ટ:',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                  Text(
                    '-${formatCurrency(_discount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'દેય:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    formatCurrency(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('બિલ ક્લીયર કરો'),
                onPressed: _billLines.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _billLines.clear();
                          _discount = 0;
                        });
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple bill line item model.
class BillLineItem {
  final Item item;
  final double qtyGrams;
  final double amount;

  BillLineItem({
    required this.item,
    required this.qtyGrams,
    required this.amount,
  });
}
