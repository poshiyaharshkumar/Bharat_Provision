import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/bill_formatter.dart';
import '../../core/utils/currency_format.dart';
import '../../data/models/bill.dart';
import '../../data/models/bill_item.dart';

/// Bill preview screen that displays formatted bill with shop details
class BillPreviewScreen extends ConsumerWidget {
  const BillPreviewScreen({
    required this.bill,
    required this.billItems,
    required this.shopDetails,
    required this.itemNames,
    this.customerName,
    this.customerPhone,
    super.key,
  });

  final Bill bill;
  final List<BillItem> billItems;
  final Map<String, String> shopDetails;
  final Map<int, String> itemNames;
  final String? customerName;
  final String? customerPhone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedBill = BillFormatter.formatBill(
      bill: bill,
      billItems: billItems,
      shopDetails: shopDetails,
      itemNames: itemNames,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Preview'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _BillDisplay(bill: formattedBill),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _shareBill(context, formattedBill),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _printBill(context, formattedBill),
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareBill(BuildContext context, FormattedBill bill) {
    // Implementation for sharing bill
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _printBill(BuildContext context, FormattedBill bill) {
    // Implementation for printing bill
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon')),
    );
  }
}

class _BillDisplay extends StatelessWidget {
  const _BillDisplay({required this.bill});

  final FormattedBill bill;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      bill.shopName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (bill.shopAddress.isNotEmpty)
                      Text(
                        bill.shopAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (bill.shopPhone.isNotEmpty)
                      Text(
                        'Ph: ${bill.shopPhone}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (bill.gstin.isNotEmpty)
                      Text(
                        'GSTIN: ${bill.gstin}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Bill details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bill.billNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(bill.billDate, style: const TextStyle(fontSize: 12)),
                      Text(bill.billTime, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer details
              if (bill.customerName.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${bill.customerName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (bill.customerPhone.isNotEmpty)
                      Text(
                        'Phone: ${bill.customerPhone}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),

              const Divider(),
              const SizedBox(height: 8),

              // Items header
              Row(
                children: const [
                  Expanded(flex: 3, child: Text('Item')),
                  Expanded(
                    flex: 1,
                    child: Text('Qty', textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('Price', textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('Amount', textAlign: TextAlign.right),
                  ),
                ],
              ),
              const Divider(),

              // Items
              ...bill.lineItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${item.quantity} ${item.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item.quantity.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          formatCurrency(item.unitPrice),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          formatCurrency(item.lineTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const Divider(),
              const SizedBox(height: 8),

              // Totals
              _TotalRow(label: 'Subtotal', amount: bill.subtotal),
              if (bill.discountAmount > 0)
                _TotalRow(
                  label: 'Discount',
                  amount: -bill.discountAmount,
                  color: Colors.red,
                ),
              if (bill.cgst > 0) _TotalRow(label: 'CGST', amount: bill.cgst),
              if (bill.sgst > 0) _TotalRow(label: 'SGST', amount: bill.sgst),
              const Divider(),
              _TotalRow(
                label: 'TOTAL',
                amount: bill.totalAmount,
                isBold: true,
                fontSize: 16,
              ),

              const SizedBox(height: 16),

              // Payment mode
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Payment: ${bill.paymentMode.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Footer
              if (bill.billFooter.isNotEmpty)
                Column(
                  children: [
                    const Divider(),
                    Text(
                      bill.billFooter,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Thank you! Visit again.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.color,
    this.fontSize = 14,
  });

  final String label;
  final double amount;
  final bool isBold;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            formatCurrency(amount.abs()),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
