import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/numpad.dart';

/// Shows amount due, numpad for amount received, change, and payment mode.
/// onConfirm(paidAmount, paymentMode).
void showPaymentDialog(
  BuildContext context, {
  required double amountDue,
  required void Function(double paidAmount, String paymentMode) onConfirm,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PaymentSheet(
      amountDue: amountDue,
      onConfirm: onConfirm,
    ),
  );
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.amountDue,
    required this.onConfirm,
  });

  final double amountDue;
  final void Function(double paidAmount, String paymentMode) onConfirm;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _receivedInput = '';
  String _paymentMode = 'cash';

  double get _received => double.tryParse(_receivedInput) ?? 0;
  double get _change => (_received - widget.amountDue).clamp(0.0, double.infinity);

  void _submit() {
    if (_received < widget.amountDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('મળેલ રકમ બિલ કરતાં ઓછી છે.')),
      );
      return;
    }
    widget.onConfirm(_received, _paymentMode);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.payment, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'ચુકવણી',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('બિલ રકમ'),
              trailing: Text(
                Formatters.formatCurrency(widget.amountDue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ListTile(
              title: const Text('મળેલ રકમ'),
              trailing: Text(
                Formatters.formatCurrency(_received),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            if (_received >= widget.amountDue && _change > 0)
              ListTile(
                title: const Text('બાકી આપવાની'),
                trailing: Text(
                  Formatters.formatCurrency(_change),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('ચુકવણી પદ્ધતિ'),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('નগદ'),
                    value: 'cash',
                    groupValue: _paymentMode,
                    onChanged: (v) => setState(() => _paymentMode = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('UPI'),
                    value: 'upi',
                    groupValue: _paymentMode,
                    onChanged: (v) => setState(() => _paymentMode = v!),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Numpad(
                initialValue: _receivedInput,
                onChanged: (value) => setState(() => _receivedInput = value),
                onSubmit: _submit,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('બીલ પૂર્ણ કરો'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
