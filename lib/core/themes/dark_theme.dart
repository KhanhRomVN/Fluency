import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'DM Sans',
  textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'DM Sans',
      ),
  primaryTextTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'DM Sans',
      ),
  useMaterial3: true,
  // Customize dark theme as needed
);
