import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primary,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderFocus,
    required this.cardBackground,
    required this.inputBackground,
    required this.inputBorderDefault,
    required this.inputBorderFocus,
    required this.dialogBackground,
    required this.dropdownBackground,
    required this.dropdownBorder,
    required this.buttonBg,
    required this.buttonText,
    required this.buttonBorder,
    required this.buttonSecondBg,
    required this.drawerBackground,
    required this.tabBorder,
    required this.tabItemBackground,
    required this.tabItemFocusBg,
    required this.tabItemBorder,
    required this.tabItemFocusBorder,
    required this.divider,
  });

  final Color primary;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderFocus;
  final Color cardBackground;
  final Color inputBackground;
  final Color inputBorderDefault;
  final Color inputBorderFocus;
  final Color dialogBackground;
  final Color dropdownBackground;
  final Color dropdownBorder;
  final Color buttonBg;
  final Color buttonText;
  final Color buttonBorder;
  final Color buttonSecondBg;
  final Color drawerBackground;
  final Color tabBorder;
  final Color tabItemBackground;
  final Color tabItemFocusBg;
  final Color tabItemBorder;
  final Color tabItemFocusBorder;
  final Color divider;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? borderFocus,
    Color? cardBackground,
    Color? inputBackground,
    Color? inputBorderDefault,
    Color? inputBorderFocus,
    Color? dialogBackground,
    Color? dropdownBackground,
    Color? dropdownBorder,
    Color? buttonBg,
    Color? buttonText,
    Color? buttonBorder,
    Color? buttonSecondBg,
    Color? drawerBackground,
    Color? tabBorder,
    Color? tabItemBackground,
    Color? tabItemFocusBg,
    Color? tabItemBorder,
    Color? tabItemFocusBorder,
    Color? divider,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      borderFocus: borderFocus ?? this.borderFocus,
      cardBackground: cardBackground ?? this.cardBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorderDefault: inputBorderDefault ?? this.inputBorderDefault,
      inputBorderFocus: inputBorderFocus ?? this.inputBorderFocus,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      dropdownBackground: dropdownBackground ?? this.dropdownBackground,
      dropdownBorder: dropdownBorder ?? this.dropdownBorder,
      buttonBg: buttonBg ?? this.buttonBg,
      buttonText: buttonText ?? this.buttonText,
      buttonBorder: buttonBorder ?? this.buttonBorder,
      buttonSecondBg: buttonSecondBg ?? this.buttonSecondBg,
      drawerBackground: drawerBackground ?? this.drawerBackground,
      tabBorder: tabBorder ?? this.tabBorder,
      tabItemBackground: tabItemBackground ?? this.tabItemBackground,
      tabItemFocusBg: tabItemFocusBg ?? this.tabItemFocusBg,
      tabItemBorder: tabItemBorder ?? this.tabItemBorder,
      tabItemFocusBorder: tabItemFocusBorder ?? this.tabItemFocusBorder,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }

    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorderDefault:
          Color.lerp(inputBorderDefault, other.inputBorderDefault, t)!,
      inputBorderFocus:
          Color.lerp(inputBorderFocus, other.inputBorderFocus, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
      dropdownBackground:
          Color.lerp(dropdownBackground, other.dropdownBackground, t)!,
      dropdownBorder: Color.lerp(dropdownBorder, other.dropdownBorder, t)!,
      buttonBg: Color.lerp(buttonBg, other.buttonBg, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
      buttonBorder: Color.lerp(buttonBorder, other.buttonBorder, t)!,
      buttonSecondBg: Color.lerp(buttonSecondBg, other.buttonSecondBg, t)!,
      drawerBackground:
          Color.lerp(drawerBackground, other.drawerBackground, t)!,
      tabBorder: Color.lerp(tabBorder, other.tabBorder, t)!,
      tabItemBackground:
          Color.lerp(tabItemBackground, other.tabItemBackground, t)!,
      tabItemFocusBg: Color.lerp(tabItemFocusBg, other.tabItemFocusBg, t)!,
      tabItemBorder: Color.lerp(tabItemBorder, other.tabItemBorder, t)!,
      tabItemFocusBorder:
          Color.lerp(tabItemFocusBorder, other.tabItemFocusBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
