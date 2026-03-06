import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData buildTheme({bool largeText = false}) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
      useMaterial3: true,
    );

    final textTheme = GoogleFonts.notoSansGujaratiTextTheme(
      base.textTheme,
    );

    final scaledTextTheme = largeText
        ? textTheme.apply(
            fontSizeFactor: 1.2,
          )
        : textTheme;

    return base.copyWith(
      textTheme: scaledTextTheme,
      primaryTextTheme: scaledTextTheme,
      scaffoldBackgroundColor: Colors.grey.shade50,
      appBarTheme: AppBarTheme(
        backgroundColor: base.colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: scaledTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
        ),
      ),
    );
  }
}

