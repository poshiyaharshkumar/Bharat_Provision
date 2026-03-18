import 'package:flutter/material.dart';

import '../core/widgets/app_scaffold.dart';
import '../features/billing/billing_home_screen.dart';
import '../features/inventory/category_list_screen.dart';
import '../features/inventory/item_list_screen.dart';
import '../features/inventory/item_edit_screen.dart';
import '../features/khata/customer_list_screen.dart';
import '../features/khata/customer_khata_detail_screen.dart';
import '../features/khata/customer_edit_screen.dart';
import '../features/khata/khata_screen.dart';
import '../features/reports/reports_home_screen.dart';
import '../features/returns/return_history_screen.dart';
import '../features/returns/return_screen.dart';
import '../features/returns/replace_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stock/stock_dashboard_screen.dart';
import '../features/stock/add_stock_screen.dart';
import '../features/stock/stock_history_screen.dart';
import '../shared/models/product_model.dart';
import '../features/udhaar/udhaar_dashboard_screen.dart';
import '../features/udhaar/customer_ledger_screen.dart';
import '../features/udhaar/collect_payment_screen.dart';
import '../features/udhaar/final_total_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/reports/pl_report_screen.dart';
import '../features/reports/daily_report_screen.dart';
import '../features/expenses/add_expense_screen.dart';
import '../features/expenses/expense_list_screen.dart';

class AppRouter {
  AppRouter._();

  static const String billing = '/billing';
  static const String dashboard = '/';
  static const String inventory = '/inventory';
  static const String customers = '/customers';
  static const String khata = '/khata';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String itemAdd = '/inventory/add';
  static const String itemEdit = '/inventory/edit';
  static const String categories = '/inventory/categories';
  static const String customerAdd = '/khata/add';
  static const String customerEdit = '/khata/edit';
  static const String customerKhata = '/khata/detail';
  static const String stockDashboard = '/stock';
  static const String stockAdd = '/stock/add';
  static const String stockHistory = '/stock/history';
  static const String returnsNew = '/returns/new';
  static const String returnsReplace = '/returns/replace';
  static const String returnsHistory = '/returns/history';
  static const String udhaarDashboard = '/udhaar';
  static const String udhaarCustomer = '/udhaar/customer';
  static const String udhaarCollect = '/udhaar/collect';
  static const String udhaarFinal = '/udhaar/final';
  static const String plReport = '/reports/pl';
  static const String dailyReport = '/reports/daily';
  static const String addExpense = '/expenses/add';
  static const String expenseList = '/expenses';

  static const List<String> _mainRoutes = [
    dashboard,
    inventory,
    customers,
    reports,
    settings,
    udhaarDashboard,
  ];

  static int indexForRoute(String route) {
    final i = _mainRoutes.indexOf(route);
    return i >= 0 ? i : 0;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case dashboard:
        return _buildShell(0, const DashboardScreen());
      case billing:
        return _build(const BillingHomeScreen());
      case inventory:
        return _buildShell(1, const ItemListScreen());
      case customers:
        return _buildShell(2, const CustomerListScreen());
      case khata:
        return _buildShell(
          2,
          const KhataScreen(),
        ); // same index? Wait, perhaps change index.
      case reports:
        return _buildShell(3, const ReportsHomeScreen());
      case settings:
        return _buildShell(4, const SettingsScreen());
      case categories:
        return _build(const CategoryListScreen());
      case itemAdd:
        return _build(const ItemEditScreen());
      case itemEdit:
        final id = routeSettings.arguments as int?;
        return _build(ItemEditScreen(itemId: id));
      case customerAdd:
        return _build(const CustomerEditScreen());
      case customerEdit:
        final id = routeSettings.arguments as int?;
        return _build(CustomerEditScreen(customerId: id));
      case customerKhata:
        final id = routeSettings.arguments as int;
        return _build(CustomerKhataDetailScreen(customerId: id));
      case stockDashboard:
        return _buildShell(1, const StockDashboardScreen());
      case stockAdd:
        final product = routeSettings.arguments as Product?;
        return _build(AddStockScreen(prefilledProduct: product));
      case stockHistory:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        final productId = args?['productId'] as int?;
        final productName = args?['productName'] as String?;
        if (productId != null && productName != null) {
          return _build(
            StockHistoryScreen(productId: productId, productName: productName),
          );
        }
        return _build(
          Scaffold(
            body: Center(child: Text('Not found: ${routeSettings.name}')),
          ),
        );
      case returnsNew:
        return _build(const ReturnScreen());
      case returnsReplace:
        return _build(const ReplaceScreen());
      case returnsHistory:
        return _build(const ReturnHistoryScreen());
      case udhaarDashboard:
        return _buildShell(5, const UdhaarDashboardScreen());
      case udhaarCustomer:
        final customerId = routeSettings.arguments as int;
        return _build(CustomerLedgerScreen(customerId: customerId));
      case udhaarCollect:
        final customerId = routeSettings.arguments as int;
        return _build(CollectPaymentScreen(customerId: customerId));
      case udhaarFinal:
        final customerId = routeSettings.arguments as int;
        return _build(FinalTotalScreen(customerId: customerId));
      case plReport:
        return _build(const PLReportScreen());
      case dailyReport:
        return _build(const DailyReportScreen());
      case khata:
        return _build(const KhataScreen());
      case addExpense:
        return _build(const AddExpenseScreen());
      case expenseList:
        return _build(const ExpenseListScreen());
      default:
        return _build(
          Scaffold(
            body: Center(child: Text('Not found: ${routeSettings.name}')),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildShell(int index, Widget child) {
    return MaterialPageRoute(
      builder: (context) => AppScaffold(
        currentIndex: index,
        onDestinationSelected: (i) {
          Navigator.of(context).pushReplacementNamed(_mainRoutes[i]);
        },
        child: child,
      ),
    );
  }

  static MaterialPageRoute<dynamic> _build(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
