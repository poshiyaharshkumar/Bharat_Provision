import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/providers.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  ({double total, int count})? _result;
  bool _loading = false;

  Future<void> _runReport() async {
    setState(() => _loading = true);
    final repo = ref.read(billRepositoryProvider);
    try {
      final total = await repo.getTotalSalesForDateRange(_from, _to);
      final count = await repo.getBillCountForDateRange(_from, _to);
      if (mounted) {
        setState(() {
          _result = (total: total, count: count);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ભૂલ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('વેચાણ અહેવાલ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('તારીખ શ્રેણી પસંદ કરો'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _from,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null && mounted) setState(() => _from = d);
                  },
                  child: Text(Formatters.formatDate(_from)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('થી'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _to,
                      firstDate: _from,
                      lastDate: DateTime.now(),
                    );
                    if (d != null && mounted) setState(() => _to = d);
                  },
                  child: Text(Formatters.formatDate(_to)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _runReport,
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('અહેવાલ બતાવો'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'કુલ વેચાણ: ${Formatters.formatCurrency(_result!.total)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('બિલની સંખ્યા: ${_result!.count}'),
                    if (_result!.count > 0)
                      Text(
                        'સરેરાશ બિલ: ${Formatters.formatCurrency(_result!.total / _result!.count)}',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
