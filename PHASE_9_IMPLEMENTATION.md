# Phase 9: Settings System - PIN-Protected, 3-Level Auth, Superadmin Panel Implementation

## Overview
This implementation provides a complete PIN-protected settings system with 3-level authentication (Superadmin, Admin, Employee), comprehensive settings management, module toggling, and specialized managers for expense accounts and transliteration dictionary.

## Key Features Implemented

### 1. **Authentication System**
- **3-Role System**: Superadmin (6-digit PIN), Admin (4-6 digit PIN), Employee (4-6 digit PIN)
- **PIN Storage**: Secure storage using `flutter_secure_storage` with SHA-256 hashing
- **Session Management**: Configurable session timeout (default 5 minutes) with app lifecycle detection
- **PIN Attempts**: 3-strike system with 30-second lockout after failed attempts
- **Session Expiry**: Automatic logout when app goes to background and timeout is exceeded

### 2. **Login Screen** (`LoginScreen`)
- Role selection with color-coded buttons:
  - 🟣 Superadmin (Purple)
  - 🔵 Admin (Blue)
  - 🟢 Employee (Green)
- PIN numpad with visual feedback:
  - Dot indicators (not digits shown)
  - Shake animation on wrong PIN
  - 30-second lockout with countdown
- Auto-advance when PIN length is reached

### 3. **Settings Screen** (`SettingsScreen`)
Tab-based interface with 7 sections:
1. **Shop Info** - Shop name, address, phone, GST number
2. **Bill Settings** - Customer name, payment mode, weight, GST calculation toggles
3. **Print Settings** - Receipt options and printer connectivity
4. **Reminder Settings** - WhatsApp, SMS, PDF statement toggles
5. **Security Settings** - Session timeout, require PIN on open, PIN management
6. **Display Settings** - Large text toggle (+20% font size globally)
7. **Data Management** - Export backup, database info, bill counter reset + Links to Managers

**Access Control**: Admin and Superadmin only (RoleGuard applied)

### 4. **SuperAdmin Panel** (`SuperadminPanelScreen`)
Requires 6-digit PIN re-verification on entry (double verification).

3 tabs:
1. **Module Manager** (`સુવિધા ઓન/ઓફ`)
   - Toggle 11 modules:
     - ઉધાર સિસ્ટમ (Udhaar System)
     - રિટર્ન સિસ્ટમ (Returns)
     - બદલી સિસ્ટમ (Replacements)
     - સ્ટોક ચેતવણી (Stock Alerts)
     - P&L રિપોર્ટ (Daily P&L)
     - ખાતું (Khata)
     - ખર્ચ ખાતા (Expense Accounts)
     - 5 બિલ ટેબ (Multi-bill Tabs)
     - Reminder modules (WhatsApp, SMS, PDF)
   - **When disabled**: Nav items COMPLETELY hidden, routes become inaccessible

2. **User Manager** (`વપરાશકર્તા`)
   - Change Admin PIN
   - Change Employee PIN
   - View last login times

3. **Shop Config** (`દુકાન સેટ`)
   - Reseller configuration: Shop name, address, phone, license notes
   - Wipe All Data button (requires typing "RESET" + PIN confirmation)

### 5. **Expense Accounts Manager** (`ExpenseAccountsManagerScreen`)
- **Default Accounts** (6): ભાડું, વીજળી, પગાર, ફોન, ખરીદી, અન્ય
- **Features**:
  - Add new accounts (Gujarati name, English name, type: FIXED/VARIABLE, typical amount)
  - Edit existing accounts
  - Toggle active/inactive status (soft-delete)
  - Cannot delete accounts with existing expense entries
  - Reset to Defaults button

### 6. **Transliteration Dictionary Manager** (`TransliterationDictionaryScreen`)
- **Built-in Entries** (with lock icon): Cannot be deleted or edited
- **Custom Entries**: Full CRUD operations
- **Features**:
  - Add custom mapping (phonetic key → Gujarati text)
  - Search existing mappings
  - Delete custom entries
  - Reset Custom Entries button (removes all custom, keeps built-in)

### 7. **PIN Management Flows**

#### Change My PIN (`ChangePinScreen`)
- 3-step wizard:
  1. Verify old PIN
  2. Enter new PIN
  3. Confirm new PIN
- Available to all roles from Security tab
- Back navigation between steps

#### Change Employee PIN (Superadmin/Admin only)
- Same 3-step flow
- Requires verifying the actor's own PIN first

### 8. **Module Toggle System** (Reactive Navigation)
- **Provider**: `navigationItemsProvider` watches `moduleSettingsProvider`
- **Behavior**: 
  - Disabled modules immediately hide from nav (no greying out)
  - Routes become inaccessible
  - Persists across sessions
  - Updates reflected in real-time after toggling

### 9. **Session Timeout**
- **Default**: 5 minutes (configurable in Security tab)
- **Trigger**: App goes to background or screen turns off
- **Action**: Shows login screen again on resume if expired
- Clears Riverpod auth state on timeout

## File Structure

```
lib/features/settings/
├── models/
│   └── auth_models.dart          # AuthSession, PinAttempt
├── providers/
│   └── auth_provider.dart        # Auth state management (Riverpod)
├── services/
│   └── pin_storage_service.dart  # Secure storage wrapper
├── utils/
│   └── pin_utils.dart            # PIN hashing and validation
├── widgets/
│   ├── auth_gate.dart            # App-level auth wrapper
│   └── pin_numpad.dart           # PIN entry widget
├── screens/
│   ├── login_screen.dart         # 3-role login with numpad
│   ├── settings_screen.dart      # Main settings (7 tabs)
│   ├── pin_verification_screen.dart  # PIN re-verification & change
│   ├── superadmin_panel_screen.dart  # Superadmin only (3 tabs)
│   ├── expense_accounts_manager_screen.dart   # Account CRUD
│   └── transliteration_dictionary_screen.dart # Dictionary CRUD
├── settings_providers.dart       # Module and feature toggles
└── settings.dart                 # Public API barrel

lib/core/navigation/
└── nav_provider.dart             # Reactive navigation provider

lib/core/widgets/
└── app_scaffold.dart             # Updated for module-aware nav
```

## Integrations

### main.dart Changes
1. ✅ Wrapped `_MainShell` with `AuthGate`
2. ✅ Added `WidgetsBindingObserver` for app lifecycle
3. ✅ Session expiry check on app resume

### Providers Ecosystem
- **secureStorageProvider**: Flutter Secure Storage instance
- **pinStorageProvider**: PIN storage service
- **authSessionProvider**: Current auth state (StateNotifier)
- **pinAttemptProvider**: PIN attempt tracking
- **moduleSettingsProvider**: Module enable/disable state
- **featureToggleProvider**: Feature toggles visible in settings
- **securitySettingsProvider**: Session timeout and PIN settings
- **navigationItemsProvider**: Reactive nav items based on modules

## Testing Scenario Walkthrough

### Test 1: PIN System (Most Important)
```
1. App opens → Shows login (if require_pin_on_open is true)
2. Select role → Shows numpad with dots only
3. Enter wrong PIN (e.g., "0001") → Shake animation + Gujarati error
4. Enter correct PIN (e.g., "0000") → Settings opens
5. Settings → Security → Change My PIN
6. Verify old PIN → Enter new PIN → Confirm → Success
7. Logout (if available) → Re-login with new PIN → Works
```

### Test 2: Module Toggles (Critical)
```
1. Login as Superadmin → Settings → Superadmin Panel
2. Module Manager → turn OFF "ઉધાર સિસ્ટમ"
3. Back to main app → Udhaar nav item COMPLETELY GONE (not greyed)
4. Logout → Login as Admin → Udhaar STILL not visible
5. Back to Superadmin → turn Udhaar ON → Nav item reappears immediately
```

### Test 3: Superadmin PIN Re-verification
```
1. Already logged in as Superadmin
2. Settings → Superadmin Panel
3. App asks for 6-digit PIN AGAIN (intentional double verification)
4. Enter wrong PIN → Blocked
5. Enter correct PIN → Panel opens
```

### Test 4: Session Timeout
```
1. Settings → Security → set timeout to 1 minute
2. Use app normally
3. Press home button (app to background) for 1+ minute
4. Return to app → Login screen shown (not the previous screen)
5. Re-login → Back in app
```

### Test 5: Expense Accounts
```
1. Settings → Data → Expense Accounts
2. See 6 default accounts: ભાડું, વીજળી, પગાર, ફોન, ખરીદી, અન્ય
3. Add new: "ઈંધણ" (Fuel), VARIABLE, ₹2,000
4. Appears in list ✓
5. Go to Add Expense → "ઈંધણ" in dropdown ✓
6. Back to manager → toggle "ઈંધણ" inactive
7. Add Expense → "ઈંધણ" NO LONGER in dropdown ✓
8. Cannot delete ભાડું if it has past entries → only deactivate
```

### Test 6: Transliteration Dictionary
```
1. Settings → Data → Transliteration Dictionary
2. See built-in entries with lock icon
3. Try to delete built-in entry → Blocked ✓
4. Add custom: "kothmir" → "કોથમીર"
5. Products → search "kothmir" → finds "કોથમીર" ✓
6. Back to dictionary → delete "kothmir"
7. Products → search "kothmir" → NOT found ✓
```

## Known Implementation Notes

1. **Module Toggles**: Watch `moduleSettingsProvider` in your screens to conditionally render sections
2. **Repository Integration**: TODO items exist in settings screens for saving changes to database
3. **Printer Test**: Platform-specific (Bluetooth Android, USB Windows)
4. **Data Export**: Not yet implemented (TODO in Data Management tab)
5. **Last Login Times**: Need to update user last_login after successful authentication
6. **Wipe Functionality**: Needs database wipe implementation with transaction

## Dependencies Added
- ✅ `flutter_secure_storage: ^9.0.0` - For secure PIN storage

## Future Enhancements
1. Biometric authentication as alternative to PIN
2. PIN expiry/change reminders
3. Login attempt logs
4. Two-factor authentication option
5. Role-based feature limitations within modules
6. PIN complexity requirements (digits + special chars)
7. Session analytics / login history per role
