import 'package:intl/intl.dart';
import '../../data/models/bill.dart';
import '../../data/models/bill_item.dart';
import 'currency_format.dart';

/// Model for formatted bill display
class FormattedBill {
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String gstin;
  final String billNumber;
  final String billDate;
  final String billTime;
  final String customerName;
  final String customerPhone;
  final List<FormattedLineItem> lineItems;
  final double subtotal;
  final double discountAmount;
  final double cgst;
  final double sgst;
  final double totalAmount;
  final String paymentMode;
  final String billFooter;

  FormattedBill({
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.gstin,
    required this.billNumber,
    required this.billDate,
    required this.billTime,
    required this.customerName,
    required this.customerPhone,
    required this.lineItems,
    required this.subtotal,
    required this.discountAmount,
    required this.cgst,
    required this.sgst,
    required this.totalAmount,
    required this.paymentMode,
    required this.billFooter,
  });
}

class FormattedLineItem {
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;

  FormattedLineItem({
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
  });
}

/// Formats bill data for display with shop details and proper layout
class BillFormatter {
  /// Formats a complete bill with all details for display
  static FormattedBill formatBill({
    required Bill bill,
    required List<BillItem> billItems,
    required Map<String, String> shopDetails,
    required Map<int, String> itemNames,
    String? customerName = '',
    String? customerPhone = '',
  }) {
    // Calculate tax amounts (currently GST is split 50-50 for CGST and SGST)
    // Total tax is included in totalAmount calculation
    const gstRate = 0.0; // Change to 0.05 for 5% GST or 0.12 for 12% GST etc.
    final taxAmount = bill.subtotal * gstRate;
    final cgst = taxAmount / 2;
    final sgst = taxAmount / 2;

    // Format line items
    final lineItems = billItems.map((item) {
      return FormattedLineItem(
        itemName: itemNames[item.itemId] ?? 'Unknown Item',
        quantity: item.quantity,
        unit: 'Kg', // Default unit - can be made dynamic
        unitPrice: item.unitPrice,
        lineTotal: item.lineTotal,
      );
    }).toList();

    final billDateTime = DateTime.fromMillisecondsSinceEpoch(bill.dateTime);

    return FormattedBill(
      shopName: shopDetails['shop_name'] ?? 'Shop Name',
      shopAddress: shopDetails['shop_address'] ?? 'Shop Address',
      shopPhone: shopDetails['shop_phone'] ?? 'Phone',
      gstin: shopDetails['gstin'] ?? '',
      billNumber: 'Bill #${bill.billNumber}',
      billDate: DateFormat('dd/MM/yyyy').format(billDateTime),
      billTime: DateFormat('hh:mm a').format(billDateTime),
      customerName: customerName ?? bill.customerName ?? 'Walk-in Customer',
      customerPhone: customerPhone ?? '',
      lineItems: lineItems,
      subtotal: bill.subtotal,
      discountAmount: bill.discountAmount,
      cgst: cgst,
      sgst: sgst,
      totalAmount: bill.totalAmount,
      paymentMode: bill.paymentMode,
      billFooter: shopDetails['bill_footer'] ?? '',
    );
  }

  /// Generates plain text bill for printing or export
  static String generatePlainTextBill(FormattedBill bill) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('═' * 44);
    buffer.writeln(bill.shopName.padCenter(44));
    buffer.writeln('═' * 44);
    buffer.writeln();

    // Shop details
    if (bill.shopAddress.isNotEmpty) {
      buffer.writeln(bill.shopAddress);
    }
    if (bill.shopPhone.isNotEmpty) {
      buffer.writeln('Ph: ${bill.shopPhone}');
    }
    if (bill.gstin.isNotEmpty) {
      buffer.writeln('GSTIN: ${bill.gstin}');
    }
    buffer.writeln();

    // Bill info
    buffer.writeln('${bill.billNumber}');
    buffer.writeln('Date: ${bill.billDate}  Time: ${bill.billTime}');
    buffer.writeln();

    // Customer details (if available)
    if (bill.customerName.isNotEmpty) {
      buffer.writeln('Customer: ${bill.customerName}');
      if (bill.customerPhone.isNotEmpty) {
        buffer.writeln('Phone: ${bill.customerPhone}');
      }
      buffer.writeln();
    }

    // Items header
    buffer.writeln('─' * 44);
    buffer.writeln('Item              Qty  Price     Amount');
    buffer.writeln('─' * 44);

    // Items
    for (final item in bill.lineItems) {
      final itemDisplay = _truncate(item.itemName, 16);
      final qtyDisplay = item.quantity.toStringAsFixed(2).padLeft(5);
      final priceDisplay = formatCurrency(item.unitPrice).padLeft(8);
      final amountDisplay = formatCurrency(item.lineTotal).padLeft(8);

      buffer.writeln('$itemDisplay$qtyDisplay $priceDisplay $amountDisplay');
    }

    buffer.writeln('─' * 44);

    // Totals
    final subtotalDisplay = formatCurrency(bill.subtotal).padLeft(8);
    buffer.writeln('Subtotal:${' ' * 25}${subtotalDisplay}');

    if (bill.discountAmount > 0) {
      final discountDisplay = formatCurrency(bill.discountAmount).padLeft(8);
      buffer.writeln('Discount:${' ' * 24}(${discountDisplay})');
    }

    if (bill.cgst > 0) {
      final cgstDisplay = formatCurrency(bill.cgst).padLeft(8);
      buffer.writeln('CGST:${' ' * 28}${cgstDisplay}');
    }

    if (bill.sgst > 0) {
      final sgstDisplay = formatCurrency(bill.sgst).padLeft(8);
      buffer.writeln('SGST:${' ' * 28}${sgstDisplay}');
    }

    final totalDisplay = formatCurrency(bill.totalAmount).padLeft(8);
    buffer.writeln('═' * 44);
    buffer.writeln('Total:${' ' * 28}${totalDisplay}');
    buffer.writeln('═' * 44);

    // Payment mode
    buffer.writeln('Payment: ${bill.paymentMode.toUpperCase()}');
    buffer.writeln();

    // Footer
    if (bill.billFooter.isNotEmpty) {
      buffer.writeln(bill.billFooter);
    }
    buffer.writeln();
    buffer.writeln('Thank you!'.padCenter(44));
    buffer.writeln('═' * 44);

    return buffer.toString();
  }

  static String _truncate(String text, int length) {
    return text.length > length
        ? text.substring(0, length)
        : text.padRight(length);
  }
}

extension StringPadExtension on String {
  String padCenter(int length) {
    if (this.length >= length) return this;
    final totalPad = length - this.length;
    final leftPad = totalPad ~/ 2;
    final rightPad = totalPad - leftPad;
    return ' ' * leftPad + this + ' ' * rightPad;
  }
}
