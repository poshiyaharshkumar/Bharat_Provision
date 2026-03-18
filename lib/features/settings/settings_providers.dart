import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

final largeTextProvider = StateProvider<bool>((ref) => false);

final settingsValuesProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = await ref.watch(settingsRepositoryFutureProvider.future);
  return {
    'shop_name': await repo.get('shop_name') ?? 'મારી દુકાન',
    'shop_address': await repo.get('shop_address') ?? '',
    'shop_phone': await repo.get('shop_phone') ?? '',
    'gstin': await repo.get('gstin') ?? '',
    'bill_footer': await repo.get('bill_footer') ?? '',
  };
});

// ===== Module Toggles =====
// These control whether features are visible and accessible in the app

final moduleSettingsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final repo = await ref.watch(settingsRepositoryFutureProvider.future);
  return {
    'module_udhaar': await repo.getBool('module_udhaar') ?? true,
    'module_returns': await repo.getBool('module_returns') ?? true,
    'module_replace': await repo.getBool('module_replace') ?? true,
    'module_stock_alerts': await repo.getBool('module_stock_alerts') ?? true,
    'module_daily_pl': await repo.getBool('module_daily_pl') ?? true,
    'module_khata': await repo.getBool('module_khata') ?? true,
    'module_expense_accounts':
        await repo.getBool('module_expense_accounts') ?? true,
    'module_multi_bill_tabs':
        await repo.getBool('module_multi_bill_tabs') ?? true,
    'reminder_whatsapp': await repo.getBool('reminder_whatsapp') ?? false,
    'reminder_sms': await repo.getBool('reminder_sms') ?? false,
    'reminder_pdf': await repo.getBool('reminder_pdf') ?? false,
  };
});

// Check if a specific module is enabled
final isModuleEnabledProvider = FutureProvider.family<bool, String>((
  ref,
  moduleName,
) async {
  final modules = await ref.watch(moduleSettingsProvider.future);
  return modules[moduleName] ?? true;
});

// ===== Feature Toggles (settings visible to users) =====
final featureToggleProvider = FutureProvider<Map<String, bool>>((ref) async {
  final repo = await ref.watch(settingsRepositoryFutureProvider.future);
  return {
    'module_customer_name_on_bill':
        await repo.getBool('module_customer_name_on_bill') ?? true,
    'module_payment_mode_on_bill':
        await repo.getBool('module_payment_mode_on_bill') ?? true,
    'show_weight_on_bill': await repo.getBool('show_weight_on_bill') ?? true,
    'gst_enabled': await repo.getBool('gst_enabled') ?? false,
    'print_udhaar_receipt': await repo.getBool('print_udhaar_receipt') ?? true,
    'print_payment_receipt':
        await repo.getBool('print_payment_receipt') ?? true,
    'print_final_receipt': await repo.getBool('print_final_receipt') ?? true,
    'large_text': await repo.getBool('large_text') ?? false,
  };
});

// Session security settings
final securitySettingsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = await ref.watch(settingsRepositoryFutureProvider.future);
  return {
    'session_timeout_minutes':
        int.tryParse(await repo.get('session_timeout_minutes') ?? '5') ?? 5,
    'require_pin_on_open': await repo.getBool('require_pin_on_open') ?? false,
  };
});
