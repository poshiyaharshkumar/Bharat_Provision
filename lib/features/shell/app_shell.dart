import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../billing/billing_home_screen.dart';
import '../inventory/item_list_screen.dart';
import '../khata/customer_list_screen.dart';
import '../reports/reports_home_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    final pages = <Widget>[
      const BillingHomeScreen(),
      const ItemListScreen(),
      const CustomerListScreen(),
      const ReportsHomeScreen(),
      const SettingsScreen(),
    ];

    final titles = <String>[
      AppStrings.billingTitle,
      AppStrings.inventoryTitle,
      AppStrings.khataTitle,
      AppStrings.reportsTitle,
      AppStrings.settingsTitle,
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale),
                  label: Text(AppStrings.navBilling),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2),
                  label: Text(AppStrings.navInventory),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt),
                  label: Text(AppStrings.navKhata),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart),
                  label: Text(AppStrings.navReports),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text(AppStrings.navSettings),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(titles[_selectedIndex]),
                ),
                body: pages[_selectedIndex],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout with bottom navigation
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: AppStrings.navBilling,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: AppStrings.navInventory,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: AppStrings.navKhata,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: AppStrings.navReports,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppStrings.navSettings,
          ),
        ],
      ),
    );
  }
}

