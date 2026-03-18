import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../stock/stock_providers.dart';
import '../../../shared/models/expense_account_model.dart';

class ExpenseAccountsManagerScreen extends ConsumerStatefulWidget {
  const ExpenseAccountsManagerScreen({super.key});

  @override
  ConsumerState<ExpenseAccountsManagerScreen> createState() =>
      _ExpenseAccountsManagerScreenState();
}

class _ExpenseAccountsManagerScreenState
    extends ConsumerState<ExpenseAccountsManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final accountsAsyncValue = ref.watch(expenseAccountsProvider);

    // Check access - only Admin and Superadmin
    if (session == null ||
        (session.role != 'admin' && session.role != 'superadmin')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('Only Admin and Superadmin can access this'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ખર્ચ ખાતા (Expense Accounts)'),
        centerTitle: true,
      ),
      body: accountsAsyncValue.when(
        data: (accounts) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header with action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expense Accounts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddAccountDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Accounts list
              if (accounts.isEmpty)
                const Center(child: Text('No expense accounts'))
              else
                ...accounts.map((account) {
                  return _ExpenseAccountTile(
                    account: account,
                    onEdit: () => _showEditAccountDialog(account),
                    onToggle: (isActive) {
                      // TODO: Update account status
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${account.accountNameGujarati} ${isActive ? 'activated' : 'deactivated'}',
                          ),
                        ),
                      );
                    },
                  );
                }),
              const SizedBox(height: 24),
              // Reset to defaults button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    _showResetConfirmation();
                  },
                  child: const Text('Reset to Defaults'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditAccountDialog(
        onSave: (gujaratiName, englishName, type, typicalAmount) {
          // TODO: Save to database
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$gujaratiName added successfully')),
          );
        },
      ),
    );
  }

  void _showEditAccountDialog(ExpenseAccount account) {
    showDialog(
      context: context,
      builder: (context) => _AddEditAccountDialog(
        initialGujaratiName: account.accountNameGujarati,
        initialEnglishName: account.accountNameEnglish,
        initialType: account.accountType,
        initialAmount: account.typicalAmount.toString(),
        onSave: (gujaratiName, englishName, type, typicalAmount) {
          // TODO: Update in database
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$gujaratiName updated successfully')),
          );
        },
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will recreate the 6 default expense accounts. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // TODO: Reset to defaults
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to defaults - Coming soon'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _ExpenseAccountTile extends StatelessWidget {
  final ExpenseAccount account;
  final VoidCallback onEdit;
  final Function(bool) onToggle;

  const _ExpenseAccountTile({
    required this.account,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        title: Text(account.accountNameGujarati),
        subtitle: Text(
          '${account.accountNameEnglish ?? ''} • ${account.accountType} • ₹${account.typicalAmount}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: account.isActive, onChanged: onToggle),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          ],
        ),
      ),
    );
  }
}

class _AddEditAccountDialog extends StatefulWidget {
  final String? initialGujaratiName;
  final String? initialEnglishName;
  final String? initialType;
  final String? initialAmount;
  final Function(String, String, String, double) onSave;

  const _AddEditAccountDialog({
    this.initialGujaratiName,
    this.initialEnglishName,
    this.initialType,
    this.initialAmount,
    required this.onSave,
  });

  @override
  State<_AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends State<_AddEditAccountDialog> {
  late TextEditingController _gujaratiController;
  late TextEditingController _englishController;
  late TextEditingController _amountController;
  String _selectedType = 'FIXED';

  @override
  void initState() {
    super.initState();
    _gujaratiController = TextEditingController(
      text: widget.initialGujaratiName ?? '',
    );
    _englishController = TextEditingController(
      text: widget.initialEnglishName ?? '',
    );
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
    _selectedType = widget.initialType ?? 'FIXED';
  }

  @override
  void dispose() {
    _gujaratiController.dispose();
    _englishController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialGujaratiName == null
            ? 'Add Expense Account'
            : 'Edit Expense Account',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _gujaratiController,
              decoration: const InputDecoration(
                labelText: 'Gujarati Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _englishController,
              decoration: const InputDecoration(
                labelText: 'English Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'FIXED', child: Text('Fixed')),
                DropdownMenuItem(value: 'VARIABLE', child: Text('Variable')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Typical Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_gujaratiController.text.isEmpty ||
                _englishController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }

            final amount = double.tryParse(_amountController.text) ?? 0;

            widget.onSave(
              _gujaratiController.text,
              _englishController.text,
              _selectedType,
              amount,
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
