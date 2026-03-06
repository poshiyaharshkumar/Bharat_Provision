import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../data/backup_service.dart';
import '../../data/providers.dart';
import '../users/user_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final largeText = ref.watch(largeTextProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppStrings.settingsTitle,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('મોટા અક્ષર બતાવો'),
          subtitle: const Text('વાંચવામાં સરળતા માટે ટેક્સ્ટ મોટું કરો'),
          value: largeText,
          onChanged: (value) {
            ref.read(largeTextProvider.notifier).setLargeText(value);
          },
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('યુઝર્સ'),
          subtitle: const Text('ઓનર અને સ્ટાફ મેનેજ કરો'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserListScreen(),
              ),
            );
          },
        ),
        const Divider(),
        const Text(
          'બેકઅપ અને રીસ્ટોર',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('ડેટા એક્સપોર્ટ કરો'),
          subtitle: const Text('બધો ડેટા JSON ફાઇલમાં સાચવો'),
          onTap: () async {
            try {
              final path = await BackupService.exportToJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('એક્સપોર્ટ થયું: $path')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ભૂલ: $e')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('ડેટા ઇમ્પોર્ટ કરો'),
          subtitle: const Text('પહેલાની બેકઅપ ફાઇલથી ડેટા લાવો'),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('ચેતવણી'),
                content: const Text(
                  'ઇમ્પોર્ટ કરવાથી હાલનો ડેટા બદલાઈ જશે. શું ચાલુ રાખવું છે?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('રદ કરો'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('બરાબર'),
                  ),
                ],
              ),
            );
            if (confirm != true || !context.mounted) return;
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['json'],
            );
            if (result == null || result.files.single.path == null) return;
            try {
              await BackupService.importFromJson(result.files.single.path!);
              if (context.mounted) {
                ref.invalidate(itemsListProvider);
                ref.invalidate(customersWithBalanceProvider);
                ref.invalidate(reportSummaryProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ઇમ્પોર્ટ સફળ.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ભૂલ: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
