import 'dart:io';

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/role_provider.dart';
import '../navigation/nav_provider.dart';

/// Platform-aware navigation shell: bottom nav on Android, side rail on Windows
/// Module toggling is handled reactively - disabled modules hide their nav items
class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItemsAsync = ref.watch(navigationItemsProvider);

    return navItemsAsync.when(
      data: (items) {
        final effectiveIndex = currentIndex.clamp(0, items.length - 1);
        final isDesktop = !Platform.isAndroid;

        if (isDesktop) {
          // Desktop: Side rail navigation
          final screenWidth = MediaQuery.sizeOf(context).width;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: screenWidth > 800,
                  minExtendedWidth: 160,
                  selectedIndex: effectiveIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: items
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Mobile: Bottom navigation
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: effectiveIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Navigation Error: $err'))),
    );
  }
}
