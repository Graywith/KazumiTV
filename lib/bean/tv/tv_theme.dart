import 'package:flutter/material.dart';

ThemeData compactTvTheme(ThemeData theme) {
  final text = theme.textTheme;
  TextStyle? size(TextStyle? style, double value) =>
      style?.copyWith(fontSize: value, height: 1.25);
  final typography = text.copyWith(
    displaySmall: size(text.displaySmall, 24),
    headlineLarge: size(text.headlineLarge, 24),
    headlineMedium: size(text.headlineMedium, 22),
    headlineSmall: size(text.headlineSmall, 20),
    titleLarge: size(text.titleLarge, 18),
    titleMedium: size(text.titleMedium, 15),
    titleSmall: size(text.titleSmall, 13),
    bodyLarge: size(text.bodyLarge, 14),
    bodyMedium: size(text.bodyMedium, 14),
    bodySmall: size(text.bodySmall, 12),
    labelLarge: size(text.labelLarge, 13),
    labelMedium: size(text.labelMedium, 12),
    labelSmall: size(text.labelSmall, 11),
  );
  final buttons = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    textStyle: WidgetStatePropertyAll(typography.labelLarge),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
  return theme.copyWith(
    textTheme: typography,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    iconTheme: theme.iconTheme.copyWith(size: 20),
    appBarTheme: theme.appBarTheme.copyWith(
      toolbarHeight: 44,
      titleTextStyle: typography.headlineSmall,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: buttons.merge(theme.filledButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: buttons.merge(theme.textButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: buttons.merge(theme.outlinedButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: buttons
          .copyWith(
            iconSize: const WidgetStatePropertyAll(20),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
          )
          .merge(theme.iconButtonTheme.style),
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      dense: true,
      minTileHeight: 44,
      minVerticalPadding: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    cardTheme: theme.cardTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: theme.sliderTheme.copyWith(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
    dialogTheme: theme.dialogTheme.copyWith(
      titleTextStyle: typography.titleLarge,
      contentTextStyle: typography.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
