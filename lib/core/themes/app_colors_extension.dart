import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primary,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderHover,
    required this.borderFocus,
    required this.cardBackground,
    required this.inputBackground,
    required this.inputBorderDefault,
    required this.inputBorderHover,
    required this.inputBorderFocus,
    required this.dialogBackground,
    required this.dropdownBackground,
    required this.dropdownItemHover,
    required this.dropdownBorder,
    required this.dropdownBorderHover,
    required this.sidebarBackground,
    required this.sidebarItemHover,
    required this.sidebarItemFocus,
    required this.buttonBg,
    required this.buttonBgHover,
    required this.buttonText,
    required this.buttonBorder,
    required this.buttonBorderHover,
    required this.buttonSecondBg,
    required this.buttonSecondBgHover,
    required this.bookmarkItemBg,
    required this.bookmarkItemText,
    required this.drawerBackground,
    required this.clockGradientFrom,
    required this.clockGradientTo,
    required this.cardShadow,
    required this.dialogShadow,
    required this.dropdownShadow,
    required this.tableHeaderBg,
    required this.tableHoverHeaderBg,
    required this.tableBodyBg,
    required this.tableHoverItemBodyBg,
    required this.tableFocusItemBodyBg,
    required this.tableFooterBg,
    required this.tableHoverFooterBg,
    required this.tableBorder,
    required this.tabBackground,
    required this.tabBorder,
    required this.tabHoverBorder,
    required this.tabItemBackground,
    required this.tabItemHoverBg,
    required this.tabItemFocusBg,
    required this.tabItemBorder,
    required this.tabItemHoverBorder,
    required this.tabItemFocusBorder,
    required this.divider,
  });

  final Color primary;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderHover;
  final Color borderFocus;
  final Color cardBackground;
  final Color inputBackground;
  final Color inputBorderDefault;
  final Color inputBorderHover;
  final Color inputBorderFocus;
  final Color dialogBackground;
  final Color dropdownBackground;
  final Color dropdownItemHover;
  final Color dropdownBorder;
  final Color dropdownBorderHover;
  final Color sidebarBackground;
  final Color sidebarItemHover;
  final Color sidebarItemFocus;
  final Color buttonBg;
  final Color buttonBgHover;
  final Color buttonText;
  final Color buttonBorder;
  final Color buttonBorderHover;
  final Color buttonSecondBg;
  final Color buttonSecondBgHover;
  final Color bookmarkItemBg;
  final Color bookmarkItemText;
  final Color drawerBackground;
  final Color clockGradientFrom;
  final Color clockGradientTo;
  // Shadows are tricky in ThemeExtension if stored as Strings in JSON,
  // we might want to parse them to BoxShadow, or just keep as String?
  // Let's keep them as Strings for now if they are simple css-like strings,
  // OR ideally, we construct BoxShadow.
  // The JSON has "cardShadow": "0 1px 3px 0 rgba(0, 0, 0, 0.3)" which is CSS syntax.
  // Flutter doesn't parse CSS shadow strings directly easily without a parser.
  // Implementation decision: Store as keys for now, but in actual UI code we might need a parser helper.
  // For Simplicity in this generic model, let's keep strings for shadows for now, or use Color if it meant color?
  // No, these are clearly shadows. Let's start with parsing colors first.
  // Wait, I should probably try to parse them if I can, but writing a CSS shadow parser is complex.
  // Let's just store the raw string for now and handle parsing elsewhere or later.
  final String cardShadow;
  final String dialogShadow;
  final String dropdownShadow;

  final Color tableHeaderBg;
  final Color tableHoverHeaderBg;
  final Color tableBodyBg;
  final Color tableHoverItemBodyBg;
  final Color tableFocusItemBodyBg;
  final Color tableFooterBg;
  final Color tableHoverFooterBg;
  final Color tableBorder;
  final Color tabBackground;
  final Color tabBorder;
  final Color tabHoverBorder;
  final Color tabItemBackground;
  final Color tabItemHoverBg;
  final Color tabItemFocusBg;
  final Color tabItemBorder;
  final Color tabItemHoverBorder;
  final Color tabItemFocusBorder;
  final Color divider;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? borderHover,
    Color? borderFocus,
    Color? cardBackground,
    Color? inputBackground,
    Color? inputBorderDefault,
    Color? inputBorderHover,
    Color? inputBorderFocus,
    Color? dialogBackground,
    Color? dropdownBackground,
    Color? dropdownItemHover,
    Color? dropdownBorder,
    Color? dropdownBorderHover,
    Color? sidebarBackground,
    Color? sidebarItemHover,
    Color? sidebarItemFocus,
    Color? buttonBg,
    Color? buttonBgHover,
    Color? buttonText,
    Color? buttonBorder,
    Color? buttonBorderHover,
    Color? buttonSecondBg,
    Color? buttonSecondBgHover,
    Color? bookmarkItemBg,
    Color? bookmarkItemText,
    Color? drawerBackground,
    Color? clockGradientFrom,
    Color? clockGradientTo,
    String? cardShadow,
    String? dialogShadow,
    String? dropdownShadow,
    Color? tableHeaderBg,
    Color? tableHoverHeaderBg,
    Color? tableBodyBg,
    Color? tableHoverItemBodyBg,
    Color? tableFocusItemBodyBg,
    Color? tableFooterBg,
    Color? tableHoverFooterBg,
    Color? tableBorder,
    Color? tabBackground,
    Color? tabBorder,
    Color? tabHoverBorder,
    Color? tabItemBackground,
    Color? tabItemHoverBg,
    Color? tabItemFocusBg,
    Color? tabItemBorder,
    Color? tabItemHoverBorder,
    Color? tabItemFocusBorder,
    Color? divider,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      borderHover: borderHover ?? this.borderHover,
      borderFocus: borderFocus ?? this.borderFocus,
      cardBackground: cardBackground ?? this.cardBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorderDefault: inputBorderDefault ?? this.inputBorderDefault,
      inputBorderHover: inputBorderHover ?? this.inputBorderHover,
      inputBorderFocus: inputBorderFocus ?? this.inputBorderFocus,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      dropdownBackground: dropdownBackground ?? this.dropdownBackground,
      dropdownItemHover: dropdownItemHover ?? this.dropdownItemHover,
      dropdownBorder: dropdownBorder ?? this.dropdownBorder,
      dropdownBorderHover: dropdownBorderHover ?? this.dropdownBorderHover,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarItemHover: sidebarItemHover ?? this.sidebarItemHover,
      sidebarItemFocus: sidebarItemFocus ?? this.sidebarItemFocus,
      buttonBg: buttonBg ?? this.buttonBg,
      buttonBgHover: buttonBgHover ?? this.buttonBgHover,
      buttonText: buttonText ?? this.buttonText,
      buttonBorder: buttonBorder ?? this.buttonBorder,
      buttonBorderHover: buttonBorderHover ?? this.buttonBorderHover,
      buttonSecondBg: buttonSecondBg ?? this.buttonSecondBg,
      buttonSecondBgHover: buttonSecondBgHover ?? this.buttonSecondBgHover,
      bookmarkItemBg: bookmarkItemBg ?? this.bookmarkItemBg,
      bookmarkItemText: bookmarkItemText ?? this.bookmarkItemText,
      drawerBackground: drawerBackground ?? this.drawerBackground,
      clockGradientFrom: clockGradientFrom ?? this.clockGradientFrom,
      clockGradientTo: clockGradientTo ?? this.clockGradientTo,
      cardShadow: cardShadow ?? this.cardShadow,
      dialogShadow: dialogShadow ?? this.dialogShadow,
      dropdownShadow: dropdownShadow ?? this.dropdownShadow,
      tableHeaderBg: tableHeaderBg ?? this.tableHeaderBg,
      tableHoverHeaderBg: tableHoverHeaderBg ?? this.tableHoverHeaderBg,
      tableBodyBg: tableBodyBg ?? this.tableBodyBg,
      tableHoverItemBodyBg: tableHoverItemBodyBg ?? this.tableHoverItemBodyBg,
      tableFocusItemBodyBg: tableFocusItemBodyBg ?? this.tableFocusItemBodyBg,
      tableFooterBg: tableFooterBg ?? this.tableFooterBg,
      tableHoverFooterBg: tableHoverFooterBg ?? this.tableHoverFooterBg,
      tableBorder: tableBorder ?? this.tableBorder,
      tabBackground: tabBackground ?? this.tabBackground,
      tabBorder: tabBorder ?? this.tabBorder,
      tabHoverBorder: tabHoverBorder ?? this.tabHoverBorder,
      tabItemBackground: tabItemBackground ?? this.tabItemBackground,
      tabItemHoverBg: tabItemHoverBg ?? this.tabItemHoverBg,
      tabItemFocusBg: tabItemFocusBg ?? this.tabItemFocusBg,
      tabItemBorder: tabItemBorder ?? this.tabItemBorder,
      tabItemHoverBorder: tabItemHoverBorder ?? this.tabItemHoverBorder,
      tabItemFocusBorder: tabItemFocusBorder ?? this.tabItemFocusBorder,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
      covariant ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }

    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderHover: Color.lerp(borderHover, other.borderHover, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorderDefault:
          Color.lerp(inputBorderDefault, other.inputBorderDefault, t)!,
      inputBorderHover:
          Color.lerp(inputBorderHover, other.inputBorderHover, t)!,
      inputBorderFocus:
          Color.lerp(inputBorderFocus, other.inputBorderFocus, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
      dropdownBackground:
          Color.lerp(dropdownBackground, other.dropdownBackground, t)!,
      dropdownItemHover:
          Color.lerp(dropdownItemHover, other.dropdownItemHover, t)!,
      dropdownBorder: Color.lerp(dropdownBorder, other.dropdownBorder, t)!,
      dropdownBorderHover:
          Color.lerp(dropdownBorderHover, other.dropdownBorderHover, t)!,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarItemHover:
          Color.lerp(sidebarItemHover, other.sidebarItemHover, t)!,
      sidebarItemFocus:
          Color.lerp(sidebarItemFocus, other.sidebarItemFocus, t)!,
      buttonBg: Color.lerp(buttonBg, other.buttonBg, t)!,
      buttonBgHover: Color.lerp(buttonBgHover, other.buttonBgHover, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
      buttonBorder: Color.lerp(buttonBorder, other.buttonBorder, t)!,
      buttonBorderHover:
          Color.lerp(buttonBorderHover, other.buttonBorderHover, t)!,
      buttonSecondBg: Color.lerp(buttonSecondBg, other.buttonSecondBg, t)!,
      buttonSecondBgHover:
          Color.lerp(buttonSecondBgHover, other.buttonSecondBgHover, t)!,
      bookmarkItemBg: Color.lerp(bookmarkItemBg, other.bookmarkItemBg, t)!,
      bookmarkItemText:
          Color.lerp(bookmarkItemText, other.bookmarkItemText, t)!,
      drawerBackground:
          Color.lerp(drawerBackground, other.drawerBackground, t)!,
      clockGradientFrom:
          Color.lerp(clockGradientFrom, other.clockGradientFrom, t)!,
      clockGradientTo: Color.lerp(clockGradientTo, other.clockGradientTo, t)!,
      cardShadow: other.cardShadow, // String lerp not typical
      dialogShadow: other.dialogShadow,
      dropdownShadow: other.dropdownShadow,
      tableHeaderBg: Color.lerp(tableHeaderBg, other.tableHeaderBg, t)!,
      tableHoverHeaderBg:
          Color.lerp(tableHoverHeaderBg, other.tableHoverHeaderBg, t)!,
      tableBodyBg: Color.lerp(tableBodyBg, other.tableBodyBg, t)!,
      tableHoverItemBodyBg:
          Color.lerp(tableHoverItemBodyBg, other.tableHoverItemBodyBg, t)!,
      tableFocusItemBodyBg:
          Color.lerp(tableFocusItemBodyBg, other.tableFocusItemBodyBg, t)!,
      tableFooterBg: Color.lerp(tableFooterBg, other.tableFooterBg, t)!,
      tableHoverFooterBg:
          Color.lerp(tableHoverFooterBg, other.tableHoverFooterBg, t)!,
      tableBorder: Color.lerp(tableBorder, other.tableBorder, t)!,
      tabBackground: Color.lerp(tabBackground, other.tabBackground, t)!,
      tabBorder: Color.lerp(tabBorder, other.tabBorder, t)!,
      tabHoverBorder: Color.lerp(tabHoverBorder, other.tabHoverBorder, t)!,
      tabItemBackground:
          Color.lerp(tabItemBackground, other.tabItemBackground, t)!,
      tabItemHoverBg: Color.lerp(tabItemHoverBg, other.tabItemHoverBg, t)!,
      tabItemFocusBg: Color.lerp(tabItemFocusBg, other.tabItemFocusBg, t)!,
      tabItemBorder: Color.lerp(tabItemBorder, other.tabItemBorder, t)!,
      tabItemHoverBorder:
          Color.lerp(tabItemHoverBorder, other.tabItemHoverBorder, t)!,
      tabItemFocusBorder:
          Color.lerp(tabItemFocusBorder, other.tabItemFocusBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
