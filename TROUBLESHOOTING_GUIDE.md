# TROUBLESHOOTING & COMMON ISSUES

## Issue 1: Reports Loading with No Data

### Symptoms
- Reports screen shows "0 sales" or loading indefinitely
- Outstanding khata list is empty even though customers have balances

### Root Cause
Date format mismatch in SQL queries (prior to fix)

### Verification it's Fixed
1. Open `lib/data/repositories/report_repository.dart`
2. Look at `getSalesSummary()` method
3. Verify this line EXISTS:
   ```dart
   final result = await _db.rawQuery('''...''', [startEpoch, endEpoch, startEpoch, endEpoch]);
   ```
4. Verify these lines are GONE:
   ```dart
   final startIso = DateTime.fromMillisecondsSinceEpoch(startEpoch).toIso8601String();
   final endIso = DateTime.fromMillisecondsSinceEpoch(endEpoch).toIso8601String();
   ```

### Fix Steps if Still Broken
1. **Clear App Cache**: Delete app data and reinstall
2. **Verify Database**: Check if bill data exists in database
3. **Check Date Range**: In reports screen, ensure date range includes actual bill dates
4. **Verify Bill Dates**: Bills must have `date_time` in milliseconds, not ISO strings

### Testing Queries
```dart
// In report_repository.dart, add this test method:
Future<void> debugReportsDates() async {
  final bills = await _db.query('bills', limit: 1);
  if (bills.isNotEmpty) {
    print('Bill date_time: ${bills.first['date_time']}');
    print('Type: ${bills.first['date_time'].runtimeType}');
  }
}
```

---

## Issue 2: Shop Details Not Showing in Bills

### Symptoms
- Bill preview shows blank shop name/address
- Shop details saved but not appearing in bills

### Root Cause
- Before fix: Settings saved but providers not invalidated, so old data cached
- Before fix: No bill preview screen existed

### Verification it's Fixed
1. Check `lib/features/settings/settings_screen.dart`
2. Verify `_saveProfile()` contains:
   ```dart
   ref.invalidate(settingsValuesProvider);
   ref.invalidate(featureToggleProvider);
   ```

3. Check `lib/features/billing/billing_providers.dart`
4. Verify this provider exists:
   ```dart
   final shopDetailsForBillingProvider = FutureProvider<Map<String, String>>
   ```

5. Check bill_preview_screen.dart exists:
   ```
   lib/features/billing/bill_preview_screen.dart
   ```

### Fix Steps if Still Broken

#### Step A: Verify Settings Are Saved
```dart
// Add this to settings_screen.dart after save:
final repo = await ref.read(settingsRepositoryFutureProvider.future);
final saved = await repo.get('shop_name');
print('Saved shop_name: $saved'); // Debug output
```

#### Step B: Verify Provider Invalidation
```dart
// After saving, manually check if provider reloads:
Future<void> _verifySettingsSaved() async {
  ref.invalidate(settingsValuesProvider);
  final settings = await ref.read(settingsValuesProvider.future);
  print('Settings after invalidate: $settings');
}
```

#### Step C: Verify Bill Preview Screen
```dart
// Test the preview screen directly:
final mockBill = Bill(...);
final mockBillItems = [...];
final mockShopDetails = {
  'shop_name': 'Test Shop',
  'shop_address': 'Test Address',
  // ...
};

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BillPreviewScreen(
      bill: mockBill,
      billItems: mockBillItems,
      shopDetails: mockShopDetails,
      itemNames: {1: 'Item 1', 2: 'Item 2'},
    ),
  ),
);
```

#### Step D: Manually Test Shop Details Provider
```dart
// In any ConsumerWidget:
@override
Widget build(BuildContext context, WidgetRef ref) {
  final shopDetailsAsync = ref.watch(shopDetailsForBillingProvider);
  
  return shopDetailsAsync.when(
    data: (details) {
      return Text('Shop: ${details['shop_name']}');
    },
    error: (e, st) => Text('Error: $e'),
    loading: () => const CircularProgressIndicator(),
  );
}
```

---

## Issue 3: Bill Layout Looks Unstructured

### Symptoms
- Bill items not aligned properly
- Prices not formatted with currency symbol
- Header/footer information missing
- Layout doesn't look professional

### Root Cause
- Before fix: No bill formatter utility existed
- Before fix: No consistent bill display format

### Verification it's Fixed
1. Check file exists: `lib/core/utils/bill_formatter.dart`
2. Verify classes exist:
   - `FormattedBill`
   - `FormattedLineItem`
   - `BillFormatter`

3. Check bill_preview_screen.dart has `_BillDisplay` widget with:
   - Centered header
   - Divider lines for sections
   - Aligned item rows
   - Totals section
   - Footer message

### Fix Steps if Bill Layout Still Bad

#### Step A: Verify Bill Formatter is Used
```dart
// In bill preview, verify this code exists:
final formattedBill = BillFormatter.formatBill(
  bill: bill,
  billItems: billItems,
  shopDetails: shopDetails,
  itemNames: itemNames,
  customerName: customerName,
  customerPhone: customerPhone,
);
```

#### Step B: Adjust Text Sizes
In `bill_preview_screen.dart`, find `_BillDisplay` widget and adjust:
```dart
// Shop name - increase if too small
Text(
  bill.shopName,
  style: const TextStyle(
    fontSize: 22,  // Adjust this
    fontWeight: FontWeight.bold,
  ),
),

// Item rows - adjust for readability
Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
```

#### Step C: Adjust Spacing/Padding
```dart
// In _BillDisplay, adjust these:
SizedBox(height: 16),  // Add more space between sections
Padding(
  padding: const EdgeInsets.all(24),  // Adjust card padding
  child: ...
),
```

#### Step D: Test Plain Text Format
```dart
// Generate plain text and print to verify formatting:
final textBill = BillFormatter.generatePlainTextBill(formattedBill);
print(textBill); // This should show nicely formatted text bill
```

---

## Issue 4: Settings Lost After App Restart

### Symptoms
- Shop details saved but lost after closing/restarting app
- Settings screen shows empty fields on next load

### Root Cause
- Settings repository not saving to database correctly
- Or field labels don't match database key names

### Verification it's Fixed
1. Check `lib/features/settings/settings_screen.dart`
2. Verify `_saveProfile()` saves to correct keys:
   ```dart
   await repo.set('shop_name', _shopNameController.text);
   await repo.set('shop_address', _addressController.text);
   await repo.set('shop_phone', _phoneController.text);
   await repo.set('gstin', _gstinController.text);
   await repo.set('bill_footer', _billFooterController.text);
   ```

3. Verify `_loadSettings()` loads same keys:
   ```dart
   _shopNameController.text = await repo.get('shop_name') ?? '';
   _addressController.text = await repo.get('shop_address') ?? '';
   ```

### Fix Steps if Settings Lost

#### Step A: Verify Database Table
```dart
// Check if settings table exists and has data:
final settings = await _db.query('settings');
print('Settings in DB: $settings');
```

#### Step B: Verify Key Names Match
```dart
// Check saved vs loaded keys match exactly:
final saved = await repo.get('shop_name');
print('Saved shop_name: "$saved"'); // Debug exact value
```

#### Step C: Add Default Values
In `settings_screen.dart`, modify `_loadSettings()`:
```dart
Future<void> _loadSettings() async {
  final repo = await ref.read(settingsRepositoryFutureProvider.future);
  _shopNameController.text = (await repo.get('shop_name')) ?? 'My Shop';
  _addressController.text = (await repo.get('shop_address')) ?? '';
  // ... etc
}
```

#### Step D: Force Provider Refresh
After loading settings:
```dart
Future<void> _loadSettings() async {
  final repo = await ref.read(settingsRepositoryFutureProvider.future);
  // ... load fields ...
  
  // Force refresh of providers
  ref.invalidate(settingsValuesProvider);
  ref.invalidate(shopDetailsForBillingProvider);
}
```

---

## Issue 5: Outstanding Khata Not Showing Correctly

### Symptoms
- Outstanding khata list empty or showing wrong balances
- Customer balances not updating after khata entries

### Root Cause
Date format issues or khata_entries table not populating correctly

### Fix Steps

#### Step A: Verify Data in Database
```dart
// Check if khata_entries table has data:
final khatEntries = await _db.query('khata_entries');
print('Khata entries: $khatEntries');

// Check if customers exist:
final customers = await _db.query('customers');
print('Customers: $customers');
```

#### Step B: Test Outstanding Khata Query
```dart
// In report repository, add test method:
Future<void> debugOutstandingKhata() async {
  try {
    final result = await getOutstandingKhata();
    print('Outstanding customers: $result');
  } catch (e) {
    print('Error: $e');
  }
}
```

#### Step C: Check Customer-Khata Relationship
```dart
// Verify foreign key relationships:
final result = await _db.rawQuery('''
  SELECT c.name, ke.balance_after, ke.date_time
  FROM customers c
  LEFT JOIN khata_entries ke ON c.id = ke.customer_id
  ORDER BY ke.date_time DESC
''');
print('Customer-Khata join: $result');
```

---

## Issue 6: Bill Formatter Not Showing Proper Currency

### Symptoms
- Bill shows "450" instead of "₹450"
- Decimals not formatted (shows 450.5555 instead of 450.50)

### Root Cause
`formatCurrency()` utility not being called

### Fix Steps

#### Step A: Import Currency Formatter
```dart
import '../../core/utils/currency_format.dart';
```

#### Step B: Use in BillFormatter
```dart
// In bill_formatter.dart, verify usage:
formatCurrency(item.unitPrice)  // Should return "₹450.00"
```

#### Step C: Check Formatter Implementation
```dart
// Verify formatCurrency exists and works:
print(formatCurrency(450));      // Should print "₹450.00"
print(formatCurrency(450.5));    // Should print "₹450.50"
print(formatCurrency(0));        // Should print "₹0.00"
```

---

## Data Validation Checklist

### Before Testing Reports
- [ ] At least 1 bill exists in `bills` table
- [ ] Bill has `date_time` as milliseconds (not ISO string)
- [ ] Bill has `total_amount` > 0
- [ ] Date range in reports includes bill date

### Before Testing Shop Details
- [ ] Shop name saved in settings (via Settings screen)
- [ ] Database settings table has shop_name key
- [ ] Settings screen shows saved values after reload
- [ ] No typos in key names ('shop_name' not 'shopName')

### Before Testing Bill Preview
- [ ] Bill exists in database
- [ ] Bill items exist for that bill
- [ ] Shop details saved
- [ ] Bill formatter can find all item names

---

## Database Integrity Check

### Run this code to verify database health:
```dart
Future<void> verifyDatabaseIntegrity() async {
  try {
    // Check tables exist
    final tables = await _db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    print('Tables: ${tables.map((t) => t['name']).toList()}');

    // Check bills table
    final billCount = await _db.rawQuery('SELECT COUNT(*) as count FROM bills');
    print('Bill count: ${billCount.first['count']}');

    // Check bill_items
    final itemCount = await _db.rawQuery('SELECT COUNT(*) as count FROM bill_items');
    print('Bill items count: ${itemCount.first['count']}');

    // Check settings
    final settings = await _db.rawQuery('SELECT COUNT(*) as count FROM settings');
    print('Settings count: ${settings.first['count']}');

    // Check sample bill
    final sampleBill = await _db.query('bills', limit: 1);
    if (sampleBill.isNotEmpty) {
      print('Sample bill: ${sampleBill.first}');
      print('Bill date_time: ${sampleBill.first['date_time']}');
      print('Bill date_time type: ${sampleBill.first['date_time'].runtimeType}');
    }
  } catch (e) {
    print('Database check error: $e');
  }
}
```

---

## Performance Optimization

If app is slow after fixes:

### 1. Add Indexes to Frequently Queried Columns
```sql
CREATE INDEX IF NOT EXISTS idx_bills_date_time ON bills(date_time);
CREATE INDEX IF NOT EXISTS idx_khata_customer_id ON khata_entries(customer_id);
CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON bill_items(bill_id);
```

### 2. Limit Query Results
```dart
// In report queries, add LIMIT
final result = await _db.rawQuery(
  'SELECT * FROM bills WHERE date_time >= ? AND date_time <= ? LIMIT 1000',
  [startEpoch, endEpoch],
);
```

### 3. Use Specific Column Selection
```dart
// Instead of SELECT *
final result = await _db.query(
  'bills',
  columns: ['id', 'bill_number', 'total_amount', 'date_time'],
  where: 'date_time >= ? AND date_time <= ?',
  whereArgs: [startEpoch, endEpoch],
);
```

---

## Getting Help

If none of these fixes work:

1. **Export Debug Info**:
   ```dart
   // Add to settings screen
   final dbPath = await AppDatabase.databasePath;
   print('Database path: $dbPath');
   print('Database exists: ${File(dbPath).existsSync()}');
   ```

2. **Check Logs**:
   ```
   adb logcat | grep "flutter"  // Android
   log stream --predicate 'eventMessage contains[c] "flutter"'  // iOS
   ```

3. **Verify All Files Exist**:
   - lib/core/utils/bill_formatter.dart ✅
   - lib/features/billing/bill_preview_screen.dart ✅
   - lib/features/settings/settings_screen.dart (modified) ✅
   - lib/features/billing/billing_providers.dart (modified) ✅
   - lib/data/repositories/report_repository.dart (modified) ✅

4. **Test Riverpod Providers**:
   ```dart
   // Add to any screen
   final test = ref.watch(shopDetailsForBillingProvider);
   print('Provider test: $test');
   ```

---

## Common Code Errors

### Error: "shopDetailsForBillingProvider not found"
**Fix**: Import the provider
```dart
import '../../features/billing/billing_providers.dart';
```

### Error: "BillPreviewScreen not found"
**Fix**: Create the file `lib/features/billing/bill_preview_screen.dart`

### Error: "BillFormatter not found"
**Fix**: Create the file `lib/core/utils/bill_formatter.dart`

### Error: "formatCurrency not found"
**Fix**: Import the formatter
```dart
import '../../core/utils/currency_format.dart';
```

---

## Final Verification Steps

Run this checklist:

- [ ] Restart app
- [ ] Go to Settings, enter shop details, save
- [ ] Wait 2 seconds, reload Settings screen - verify data still there
- [ ] Go to Reports - verify sales data shows (not 0)
- [ ] Create a new bill
- [ ] Click "Preview Bill" - see professional formatted bill with shop name, address, phone
- [ ] Verify all prices show with ₹ symbol
- [ ] Verify bill layout looks clean and professional
- [ ] Share/Print buttons are present (if integrated)
- [ ] Restart app, go to Settings - shop details still there

If all pass ✅: **All fixes working correctly!**

If any fail ❌: Check troubleshooting section above for that specific issue.
