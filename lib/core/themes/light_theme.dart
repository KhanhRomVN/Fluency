import 'package:fluency/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'DM Sans',
  textTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'DM Sans',
      ),
  primaryTextTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'DM Sans',
      ),
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.light(),
  useMaterial3: true,
);
