import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/theme/app_typography.dart';

/// FORMA Design System — ThemeData for light and dark modes.
///
/// Configures Material 3 component themes to match FORMA's premium aesthetic.
class FormaTheme {
  const FormaTheme._();

  static ThemeData get lightTheme => light;
  static ThemeData get darkTheme => dark;

  // ════════════════════ Light Theme ═════════════════════════
  static ThemeData get light {
    final colors = FormaColors.light;
    final textTheme = FormaTypography.lightTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.primaryBg,
      canvasColor: colors.primaryBg,
      textTheme: textTheme,
      colorScheme: ColorScheme.light(
        primary: colors.primaryAccent,
        onPrimary: colors.primaryText,
        secondary: colors.secondaryAccent,
        onSecondary: Colors.white,
        surface: colors.cardBg,
        onSurface: colors.primaryText,
        error: colors.error,
        onError: Colors.white,
        outline: colors.divider,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primaryBg,
        foregroundColor: colors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: FormaTypography.h4,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: colors.primaryText, size: 24),
      ),
      // ─── Card ───
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusLg,
        ),
        margin: EdgeInsets.zero,
      ),
      // ─── Bottom Navigation Bar ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.cardBg,
        selectedItemColor: colors.primaryAccent,
        unselectedItemColor: colors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: FormaTypography.label.copyWith(
          color: colors.primaryAccent,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: FormaTypography.label,
      ),
      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: colors.primaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: FormaSpacing.lg,
            vertical: FormaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: FormaRadius.borderRadiusPill,
          ),
          textStyle: FormaTypography.bodySemiBold,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: FormaSpacing.lg,
            vertical: FormaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: FormaRadius.borderRadiusPill,
          ),
          side: BorderSide(color: colors.divider, width: 1.5),
          textStyle: FormaTypography.bodySemiBold,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryAccent,
          textStyle: FormaTypography.bodySemiBold,
          padding: const EdgeInsets.symmetric(
            horizontal: FormaSpacing.md,
            vertical: FormaSpacing.sm,
          ),
        ),
      ),
      // ─── Input Decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.secondaryBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FormaSpacing.md,
          vertical: FormaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide(color: colors.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        hintStyle: FormaTypography.body.copyWith(
          color: colors.secondaryText,
        ),
        labelStyle: FormaTypography.bodySmall,
        errorStyle: FormaTypography.caption.copyWith(color: colors.error),
      ),
      // ─── Floating Action Button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryAccent,
        foregroundColor: colors.primaryText,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusLg,
        ),
      ),
      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: colors.secondaryBg,
        labelStyle: FormaTypography.caption.copyWith(
          color: colors.primaryText,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusPill,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FormaSpacing.sm,
          vertical: FormaSpacing.xs,
        ),
      ),
      // ─── Bottom Sheet ───
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FormaRadius.xxl),
          ),
        ),
        elevation: 8,
        dragHandleSize: const Size(40, 4),
        dragHandleColor: colors.divider,
        showDragHandle: true,
      ),
      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusXl,
        ),
        elevation: 8,
        titleTextStyle: FormaTypography.h4,
        contentTextStyle: FormaTypography.body,
      ),
      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FormaColors.charcoal,
        contentTextStyle: FormaTypography.bodySmall.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusMd,
        ),
      ),
      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.cardBg;
          }
          return colors.secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primaryAccent;
          }
          return colors.secondaryBg;
        }),
      ),
      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primaryText,
        unselectedLabelColor: colors.secondaryText,
        labelStyle: FormaTypography.bodySemiBold.copyWith(fontSize: 14),
        unselectedLabelStyle: FormaTypography.body.copyWith(fontSize: 14),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors.primaryAccent, width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      // ─── Progress Indicator ───
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primaryAccent,
        linearTrackColor: colors.secondaryBg,
        circularTrackColor: colors.secondaryBg,
      ),
      // Extensions
      extensions: <ThemeExtension<dynamic>>[
        FormaThemeExtension(
          colors: FormaColors.light,
          icyBlue: FormaColors.icyBlue,
          coralPink: FormaColors.coralPink,
          charcoal: FormaColors.charcoal,
          warmCream: FormaColors.warmCream,
          goldenYellow: FormaColors.goldenYellow,
          concreteGrey: FormaColors.concreteGrey,
        ),
      ],
    );
  }

  // ════════════════════ Dark Theme ══════════════════════════
  static ThemeData get dark {
    final colors = FormaColors.dark;
    final textTheme = FormaTypography.darkTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.primaryBg,
      canvasColor: colors.primaryBg,
      textTheme: textTheme,
      colorScheme: ColorScheme.dark(
        primary: colors.primaryAccent,
        onPrimary: const Color(0xFF171717),
        secondary: colors.secondaryAccent,
        onSecondary: Colors.white,
        surface: colors.cardBg,
        onSurface: colors.primaryText,
        error: colors.error,
        onError: Colors.white,
        outline: colors.divider,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primaryBg,
        foregroundColor: colors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: FormaTypography.h4Dark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: colors.primaryText, size: 24),
      ),
      // ─── Card ───
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusLg,
        ),
        margin: EdgeInsets.zero,
      ),
      // ─── Bottom Navigation Bar ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.cardBg,
        selectedItemColor: colors.primaryAccent,
        unselectedItemColor: colors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: FormaTypography.labelDark.copyWith(
          color: colors.primaryAccent,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: FormaTypography.labelDark,
      ),
      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: const Color(0xFF171717),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: FormaSpacing.lg,
            vertical: FormaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: FormaRadius.borderRadiusPill,
          ),
          textStyle: FormaTypography.bodySemiBoldDark.copyWith(
            color: const Color(0xFF171717),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: FormaSpacing.lg,
            vertical: FormaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: FormaRadius.borderRadiusPill,
          ),
          side: BorderSide(color: colors.divider, width: 1.5),
          textStyle: FormaTypography.bodySemiBoldDark,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryAccent,
          textStyle: FormaTypography.bodySemiBoldDark,
          padding: const EdgeInsets.symmetric(
            horizontal: FormaSpacing.md,
            vertical: FormaSpacing.sm,
          ),
        ),
      ),
      // ─── Input Decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.secondaryBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FormaSpacing.md,
          vertical: FormaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide(color: colors.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: FormaRadius.borderRadiusMd,
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        hintStyle: FormaTypography.bodyDark.copyWith(
          color: colors.secondaryText,
        ),
        labelStyle: FormaTypography.bodySmallDark,
        errorStyle: FormaTypography.captionDark.copyWith(color: colors.error),
      ),
      // ─── Floating Action Button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryAccent,
        foregroundColor: const Color(0xFF171717),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusLg,
        ),
      ),
      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: colors.secondaryBg,
        labelStyle: FormaTypography.captionDark.copyWith(
          color: colors.primaryText,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusPill,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FormaSpacing.sm,
          vertical: FormaSpacing.xs,
        ),
      ),
      // ─── Bottom Sheet ───
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FormaRadius.xxl),
          ),
        ),
        elevation: 8,
        dragHandleSize: const Size(40, 4),
        dragHandleColor: colors.divider,
        showDragHandle: true,
      ),
      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusXl,
        ),
        elevation: 8,
        titleTextStyle: FormaTypography.h4Dark,
        contentTextStyle: FormaTypography.bodyDark,
      ),
      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FormaColors.warmCream,
        contentTextStyle: FormaTypography.bodySmall.copyWith(
          color: FormaColors.charcoal,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: FormaRadius.borderRadiusMd,
        ),
      ),
      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF171717);
          }
          return colors.secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primaryAccent;
          }
          return colors.secondaryBg;
        }),
      ),
      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primaryText,
        unselectedLabelColor: colors.secondaryText,
        labelStyle: FormaTypography.bodySemiBoldDark.copyWith(fontSize: 14),
        unselectedLabelStyle: FormaTypography.bodyDark.copyWith(fontSize: 14),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors.primaryAccent, width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      // ─── Progress Indicator ───
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primaryAccent,
        linearTrackColor: colors.secondaryBg,
        circularTrackColor: colors.secondaryBg,
      ),
      // Extensions
      extensions: <ThemeExtension<dynamic>>[
        FormaThemeExtension(
          colors: FormaColors.dark,
          icyBlue: FormaColors.icyBlue,
          coralPink: FormaColors.coralPink,
          charcoal: FormaColors.charcoal,
          warmCream: FormaColors.warmCream,
          goldenYellow: FormaColors.goldenYellow,
          concreteGrey: FormaColors.concreteGrey,
        ),
      ],
    );
  }
}

/// Custom [ThemeExtension] that exposes FORMA-specific design tokens
/// through `Theme.of(context).extension<FormaThemeExtension>()`.
class FormaThemeExtension extends ThemeExtension<FormaThemeExtension> {
  final FormaColorScheme colors;
  final Color icyBlue;
  final Color coralPink;
  final Color charcoal;
  final Color warmCream;
  final Color goldenYellow;
  final Color concreteGrey;

  const FormaThemeExtension({
    required this.colors,
    required this.icyBlue,
    required this.coralPink,
    required this.charcoal,
    required this.warmCream,
    required this.goldenYellow,
    required this.concreteGrey,
  });

  @override
  FormaThemeExtension copyWith({
    FormaColorScheme? colors,
    Color? icyBlue,
    Color? coralPink,
    Color? charcoal,
    Color? warmCream,
    Color? goldenYellow,
    Color? concreteGrey,
  }) {
    return FormaThemeExtension(
      colors: colors ?? this.colors,
      icyBlue: icyBlue ?? this.icyBlue,
      coralPink: coralPink ?? this.coralPink,
      charcoal: charcoal ?? this.charcoal,
      warmCream: warmCream ?? this.warmCream,
      goldenYellow: goldenYellow ?? this.goldenYellow,
      concreteGrey: concreteGrey ?? this.concreteGrey,
    );
  }

  @override
  FormaThemeExtension lerp(covariant FormaThemeExtension? other, double t) {
    if (other == null) return this;
    return FormaThemeExtension(
      colors: t < 0.5 ? colors : other.colors,
      icyBlue: Color.lerp(icyBlue, other.icyBlue, t)!,
      coralPink: Color.lerp(coralPink, other.coralPink, t)!,
      charcoal: Color.lerp(charcoal, other.charcoal, t)!,
      warmCream: Color.lerp(warmCream, other.warmCream, t)!,
      goldenYellow: Color.lerp(goldenYellow, other.goldenYellow, t)!,
      concreteGrey: Color.lerp(concreteGrey, other.concreteGrey, t)!,
    );
  }
}
