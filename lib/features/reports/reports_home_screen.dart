import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import 'sales_report_screen.dart';

class ReportsHomeScreen extends ConsumerWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(reportSummaryProvider('today'));
    final week = ref.watch(reportSummaryProvider('week'));
    final month = ref.watch(reportSummaryProvider('month'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppStrings.reportsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        today.when(
          data: (d) => _SummaryCard(
            title: 'આજનું વેચાણ',
            total: d.total,
            count: d.count,
            color: Colors.green,
          ),
          loading: () => const _SummaryCardPlaceholder(),
          error: (_, __) => const Card(child: ListTile(title: Text('ભૂલ'))),
        ),
        const SizedBox(height: 12),
        week.when(
          data: (d) => _SummaryCard(
            title: 'આ સપ્તાહનું વેચાણ',
            total: d.total,
            count: d.count,
            color: Colors.blue,
          ),
          loading: () => const _SummaryCardPlaceholder(),
          error: (_, __) => const Card(child: ListTile(title: Text('ભૂલ'))),
        ),
        const SizedBox(height: 12),
        month.when(
          data: (d) => _SummaryCard(
            title: 'આ મહિનાનું વેચાણ',
            total: d.total,
            count: d.count,
            color: Colors.orange,
          ),
          loading: () => const _SummaryCardPlaceholder(),
          error: (_, __) => const Card(child: ListTile(title: Text('ભૂલ'))),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SalesReportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.date_range),
            label: const Text('તારીખ પસંદ કરીને અહેવાલ જુઓ'),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.total,
    required this.count,
    required this.color,
  });

  final String title;
  final double total;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.receipt_long, color: color, size: 40),
        title: Text(title),
        subtitle: Text('બિલ: $count'),
        trailing: Text(
          Formatters.formatCurrency(total),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class _SummaryCardPlaceholder extends StatelessWidget {
  const _SummaryCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: CircularProgressIndicator(),
        title: Text('લોડ થઈ રહ્યું છે...'),
      ),
    );
  }
}
