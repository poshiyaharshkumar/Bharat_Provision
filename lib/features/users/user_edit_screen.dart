import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user.dart';
import '../../data/providers.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  const UserEditScreen({super.key, this.existing});

  final AppUser? existing;

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  String _role = 'staff';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _pinController.text = e.pin ?? '';
      _role = e.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final repo = ref.read(userRepositoryProvider);
    final user = AppUser(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      pin: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
      role: _role,
      isActive: true,
    );

    try {
      if (widget.existing == null) {
        await repo.insert(user);
      } else {
        await repo.update(user);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'નવો યુઝર' : 'યુઝર સંપાદન',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'નામ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'નામ જરૂરી છે' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN (જરૂર નથી)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text('ભૂમિકા'),
              RadioListTile<String>(
                title: const Text('Owner'),
                value: 'owner',
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v!),
              ),
              RadioListTile<String>(
                title: const Text('Staff'),
                value: 'staff',
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('સાચવો'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
