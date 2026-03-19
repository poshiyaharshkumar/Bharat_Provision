// INTEGRATION EXAMPLE
// How to integrate the bill preview and shop details into your existing billing screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart' as strings;
import '../../core/errors/error_handler.dart';
import '../../core/utils/currency_format.dart';
import '../../data/models/bill.dart';
import '../../data/models/bill_item.dart';
import '../../features/billing/bill_preview_screen.dart';
import '../../features/billing/billing_providers.dart';
import '../../data/providers.dart';

/// COMPLETE EXAMPLE: Enhanced Billing Screen with Bill Preview
class EnhancedBillingHomeScreen extends ConsumerStatefulWidget {
  const EnhancedBillingHomeScreen({super.key});

  @override
  ConsumerState<EnhancedBillingHomeScreen> createState() =>
      _EnhancedBillingHomeScreenState();
}

class _EnhancedBillingHomeScreenState
    extends ConsumerState<EnhancedBillingHomeScreen> {
  // Bill data after creation
  Bill? _lastCreatedBill;
  List<BillItem>? _lastBillItems;
  String? _selectedCustomerName;
  String? _selectedCustomerPhone;

  /// Step 1: After successfully creating/saving a bill, call this
  Future<void> _showBillPreviewAfterCreation({
    required Bill bill,
    required List<BillItem> billItems,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      // Get shop details from the new provider
      final shopDetails = await ref.read(shopDetailsForBillingProvider.future);

      // Create item names map from bill items
      final itemNames = <int, String>{};
      for (final billItem in billItems) {
        // In real implementation, fetch item name from database or pass it
        itemNames[billItem.itemId] = 'Item ${billItem.itemId}';
      }

      if (mounted) {
        // Navigate to bill preview screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BillPreviewScreen(
              bill: bill,
              billItems: billItems,
              shopDetails: shopDetails,
              itemNames: itemNames,
              customerName: customerName,
              customerPhone: customerPhone,
            ),
          ),
        );
      }
    } catch (e, st) {
      ErrorHandler.handle(e, st, context: 'BillPreview');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error showing bill preview: $e')),
        );
      }
    }
  }

  /// Step 2: Modified bill save function with preview
  Future<void> _saveBillAndShowPreview({
    required int? customerId,
    required String? customerName,
    required List<Map<String, dynamic>> billLines,
    required double discount,
    required double paidAmount,
    required String paymentMode,
  }) async {
    try {
      // Save bill using your existing bill repository
      final billRepo = await ref.read(billRepositoryFutureProvider.future);

      // Create the bill (your existing save logic)
      final billId = await billRepo.createBill(
        customerId: customerId,
        customerName: customerName,
        items: billLines,
        discountAmount: discount,
        paidAmount: paidAmount,
        paymentMode: paymentMode,
        userId: 1, // Get from auth provider
      );

      // Fetch the created bill
      final bill = await billRepo.getBill(billId);
      final billItems = await billRepo.getBillItems(billId);

      if (bill != null && billItems != null && mounted) {
        // Show preview with all details
        await _showBillPreviewAfterCreation(
          bill: bill,
          billItems: billItems,
          customerName: customerName,
          customerPhone: _selectedCustomerPhone,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully!')),
        );
      }
    } catch (e, st) {
      ErrorHandler.handle(e, st, context: 'BillSave');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving bill: $e')));
      }
    }
  }

  /// Step 3: Button handler to trigger save and preview
  void _handleCreateBillButton() {
    // Gather all bill data
    // This is your existing bill creation logic...

    // Example data structure
    final billLines = [
      {'itemId': 1, 'quantity': 2.5, 'unitPrice': 100},
      {'itemId': 2, 'quantity': 1.0, 'unitPrice': 250},
    ];

    _saveBillAndShowPreview(
      customerId: null,
      customerName: 'John Doe',
      billLines: billLines,
      discount: 50,
      paidAmount: 500,
      paymentMode: 'cash',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch shop details provider to show in UI
    final shopDetailsAsync = ref.watch(shopDetailsForBillingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing'), elevation: 0),
      body: Column(
        children: [
          // Display shop name in header (from settings)
          shopDetailsAsync.when(
            data: (shopDetails) {
              return Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.store, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopDetails['shop_name'] ?? 'Shop',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if ((shopDetails['shop_address']?.isNotEmpty ??
                              false))
                            Text(
                              shopDetails['shop_address'] ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 60),
            error: (e, st) => const SizedBox(height: 60),
          ),
          const SizedBox(height: 12),
          // Your existing billing UI components
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Your billing UI here'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _handleCreateBillButton,
                    icon: const Icon(Icons.receipt),
                    label: const Text('Create & Preview Bill'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ALTERNATIVE MINIMAL EXAMPLE (If you just want to show preview)
// ============================================================================

/// Minimal example - Just show bill preview
class MinimalBillPreviewExample extends ConsumerWidget {
  const MinimalBillPreviewExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Get shop details
        final shopDetails = await ref.read(
          shopDetailsForBillingProvider.future,
        );

        // Mock bill data - replace with real data from your app
        final mockBill = Bill(
          id: 1,
          billNumber: '001',
          dateTime: DateTime.now().millisecondsSinceEpoch,
          customerId: null,
          customerName: 'Customer Name',
          subtotal: 500,
          discountAmount: 50,
          taxAmount: 0,
          totalAmount: 450,
          paidAmount: 450,
          paymentMode: 'cash',
          userId: 1,
        );

        final mockBillItems = [
          BillItem(
            id: 1,
            billId: 1,
            itemId: 1,
            quantity: 2,
            unitPrice: 150,
            lineTotal: 300,
          ),
          BillItem(
            id: 2,
            billId: 1,
            itemId: 2,
            quantity: 1,
            unitPrice: 200,
            lineTotal: 200,
          ),
        ];

        final itemNames = {1: 'Sugar', 2: 'Salt'};

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BillPreviewScreen(
                bill: mockBill,
                billItems: mockBillItems,
                shopDetails: shopDetails,
                itemNames: itemNames,
                customerName: 'John Doe',
                customerPhone: '9876543210',
              ),
            ),
          );
        }
      },
      child: const Text('Show Bill Preview'),
    );
  }
}

// ============================================================================
// DATA CLASS REFERENCES (from existing code)
// ============================================================================

/*
// These classes should already exist in your codebase:

class Bill {
  final int id;
  final String billNumber;
  final int dateTime; // milliseconds since epoch
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final String paymentMode;
  final int userId;
  
  // ... existing implementation
}

class BillItem {
  final int id;
  final int billId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  
  // ... existing implementation
}
*/

// ============================================================================
// RIVERPOD PROVIDERS NEEDED (Already created in billing_providers.dart)
// ============================================================================

/*
// These providers are now available in billing_providers.dart:

final shopDetailsForBillingProvider = FutureProvider<Map<String, String>>((ref) async {
  // Returns shop details from settings
});

final settingsRepositoryFutureProvider = FutureProvider<SettingsRepository>((ref) async {
  // Your existing settings repository
});

final billRepositoryFutureProvider = FutureProvider<BillRepository>((ref) async {
  // Your existing bill repository
});
*/
