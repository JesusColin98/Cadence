import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.hunterGreen,
          onPrimary: AppColors.brightSnow,
          secondary: AppColors.sageGreen,
          onSecondary: AppColors.brightSnow,
          tertiary: AppColors.yellowGreen,
          onTertiary: AppColors.hunterGreen,
          error: AppColors.blushedBrick,
          onError: AppColors.brightSnow,
          surface: AppColors.brightSnow,
          onSurface: AppColors.hunterGreen,
          surfaceContainerHighest: AppColors.vanillaCream,
        ),
        scaffoldBackgroundColor: AppColors.vanillaCream,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.vanillaCream,
          foregroundColor: AppColors.hunterGreen,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: AppTypography.kicker(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.brightSnow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: const BorderSide(
              color: AppColors.sageGreen,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: const BorderSide(
              color: AppColors.blushedBrick,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.hunterGreen,
            foregroundColor: AppColors.brightSnow,
            minimumSize: const Size(double.infinity, 48),
            shape: const StadiumBorder(),
            textStyle: AppTypography.buttonText,
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.hunterGreen,
            textStyle: AppTypography.labelMedium,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.alabasterGrey,
          thickness: 1,
          space: 1,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.h1,
          displayMedium: AppTypography.h2,
          displaySmall: AppTypography.h3,
          headlineMedium: AppTypography.h4,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.labelMedium,
          labelMedium: AppTypography.labelSmall,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      );
}
