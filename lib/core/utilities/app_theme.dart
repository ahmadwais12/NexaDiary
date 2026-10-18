import 'package:flutter/material.dart';

/// The shared visual language for NexaDiary.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF635BFF);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF14B8A6);
  static const Color ink = Color(0xFF182033);
  static const Color nightInk = Color(0xFFE8ECF8);

  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      secondary: accentColor,
      surface: isDark ? const Color(0xFF152038) : Colors.white,
    );
    final surface = scheme.surface;
    final outline = isDark ? const Color(0xFF2B3957) : const Color(0xFFE6E8F0);
    final fieldColor = isDark
        ? const Color(0xFF1B2944)
        : const Color(0xFFF1F3F9);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0D1528)
          : const Color(0xFFF7F8FC),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF1B2747)
            : const Color(0xFFEFEDFF),
        foregroundColor: isDark ? nightInk : ink,
        elevation: isDark ? 2 : 3,
        scrolledUnderElevation: isDark ? 3 : 4,
        shadowColor: Colors.black.withValues(alpha: 0.20),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? nightInk : ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 1 : 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldColor,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fieldColor,
        selectedColor: primaryColor.withValues(alpha: isDark ? 0.32 : 0.14),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: surface,
        elevation: isDark ? 2 : 4,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.26 : 0.09),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withValues(alpha: isDark ? 0.30 : 0.13),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? primaryColor : scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.22)
              : primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: isDark ? Colors.white : primaryColor,
        unselectedLabelColor: isDark
            ? Colors.white.withValues(alpha: 0.7)
            : scheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: outline, width: 1.5),
      ),
      dividerTheme: DividerThemeData(color: outline, space: 1, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
