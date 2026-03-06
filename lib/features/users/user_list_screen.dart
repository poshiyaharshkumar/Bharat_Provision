import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user.dart';
import '../../data/providers.dart';
import 'user_edit_screen.dart';

final usersListProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.getAll();
});

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('યુઝર્સ'),
      ),
      body: asyncUsers.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('કોઈ યુઝર નથી.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return ListTile(
                leading: Icon(
                  u.role == 'owner' ? Icons.admin_panel_settings : Icons.person,
                ),
                title: Text(u.name),
                subtitle: Text(u.role),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => UserEditScreen(existing: u),
                    ),
                  );
                  if (updated == true) ref.invalidate(usersListProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ભૂલ: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const UserEditScreen(),
            ),
          );
          if (created == true) ref.invalidate(usersListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
