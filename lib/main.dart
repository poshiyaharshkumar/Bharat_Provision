import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

<<<<<<< HEAD
import 'core/constants/app_strings.dart';
import 'features/products/presentation/add_edit_product_screen.dart';
import 'features/products/presentation/product_list_screen.dart';
=======
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'features/shell/app_shell.dart';
>>>>>>> 4ec2d4c (Complete The Design)

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final largeTextEnabled = ref.watch(largeTextProvider);

    return MaterialApp(
<<<<<<< HEAD
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppStrings.fontFamilyGujarati,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ),
      ),
      initialRoute: '/products',
      routes: {
        '/products': (_) => const ProductListScreen(),
        '/products/add': (_) => const AddEditProductScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/products/edit' && settings.arguments is int) {
          final id = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => AddEditProductScreen(productId: id),
          );
        }
        return null;
      },
    );
  }
}
=======
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: AppTheme.buildTheme(largeText: largeTextEnabled),
      home: const AppShell(),
    );
  }
}

>>>>>>> 4ec2d4c (Complete The Design)
