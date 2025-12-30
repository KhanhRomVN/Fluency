import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';

enum ButtonIconPosition { left, right }

class Button extends StatelessWidget {
  const Button({
    super.key,
    this.size = 100,
    this.width,
    this.label,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.iconPosition = ButtonIconPosition.left,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  final double size;
  final double? width;
  final String? label;
  final Widget? icon;
  final bool loading;
  final bool disabled;
  final ButtonIconPosition iconPosition;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final scale = size / 100;
    const baseHeight = 40.0;
    const basePaddingX = 16.0;
    const basePaddingY = 8.0;
    const baseFontSize = 14.0;
    const baseBorderRadius = 6.0;
    const baseGap = 8.0;

    final height = baseHeight * scale;
    final paddingX = basePaddingX * scale;
    final finalPaddingY = basePaddingY * scale; // paddingY in TS
    final fontSize = baseFontSize * scale;
    final borderRadius = baseBorderRadius * scale;
    final gap = baseGap * scale;

    final hasText = label != null && label!.isNotEmpty;
    final hasIcon = icon != null || loading;

    // Adjust padding for icon-only buttons (logic from Button.utils.ts)
    // const finalPaddingX =
    // hasIcon && !hasText ? Math.min(paddingX, height / 3) : paddingX;
    final finalPaddingX =
        hasIcon && !hasText ? math.min(paddingX, height / 3) : paddingX;

    final isDisabled = disabled || loading;
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    final effectiveBackgroundColor = backgroundColor ??
        (isDisabled
            ? appColors?.buttonBg.withOpacity(0.6)
            : appColors?.buttonBg) ??
        Colors.blue;

    final effectiveTextColor =
        textColor ?? appColors?.buttonText ?? Colors.white;

    // Icon Size Calculation
    // const baseSize = hasText ? baseSizeWithText : baseSizeIconOnly;
    // return Math.max(Math.round(baseSize * scale), 12);
    const baseSizeWithText = 16.0;
    const baseSizeIconOnly = 20.0;
    final baseIconSize = hasText ? baseSizeWithText : baseSizeIconOnly;
    final iconSize = math.max((baseIconSize * scale).roundToDouble(), 12.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: finalPaddingX,
            vertical: finalPaddingY,
          ),
          child: Row(
            mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: effectiveTextColor,
                  ),
                ),
                if (hasText) SizedBox(width: gap),
              ] else if (hasIcon &&
                  iconPosition == ButtonIconPosition.left) ...[
                _buildIcon(iconSize),
                if (hasText) SizedBox(width: gap),
              ],
              if (hasText)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: effectiveTextColor,
                    height: 1.0, // Match React lineHeight: 1
                  ),
                ),
              if (!loading &&
                  hasIcon &&
                  iconPosition == ButtonIconPosition.right) ...[
                if (hasText) SizedBox(width: gap),
                _buildIcon(iconSize),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(double size) {
    if (icon == null) return const SizedBox();

    // If icon is Icon widget, we might want to force size?
    // In Flutter, we often wrap in IconTheme.
    return IconTheme(
      data: IconThemeData(
        size: size,
        color: textColor ?? Colors.white, // Inferred
      ),
      child: icon!,
    );
  }
}
