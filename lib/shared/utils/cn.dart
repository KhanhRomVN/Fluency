import 'package:flutter/material.dart';

/// Utility class to mimic `cn` (classnames) behavior for Flutter specific styles.
/// Allows conditionally merging lists of styles.
class Cn {
  /// Merges a list of BoxDecorations.
  /// Later decorations override earlier ones.
  static BoxDecoration mergeDecoration(List<BoxDecoration?> decorations) {
    BoxDecoration merged = const BoxDecoration();
    for (final decoration in decorations) {
      if (decoration == null) continue;
      merged = merged.copyWith(
        color: decoration.color,
        image: decoration.image,
        border: decoration.border,
        borderRadius: decoration.borderRadius,
        boxShadow: decoration.boxShadow,
        gradient: decoration.gradient,
        backgroundBlendMode: decoration.backgroundBlendMode,
        shape: decoration.shape,
      );
    }
    return merged;
  }

  /// Merges a list of TextStyles.
  /// Later styles override earlier ones.
  static TextStyle mergeTextStyle(List<TextStyle?> styles) {
    TextStyle merged = const TextStyle();
    for (final style in styles) {
      if (style == null) continue;
      merged = merged.merge(style);
    }
    return merged;
  }
}
