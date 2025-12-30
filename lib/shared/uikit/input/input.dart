import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.leftIcon,
    this.rightIcon,
    this.badges = const [],
    this.onChanged,
    this.onBadgeRemove,
    this.loading = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final List<String> badges; // Simplified badges to Strings for now
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onBadgeRemove;
  final bool loading;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _isObscure = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    // Prefix/Suffix icons
    Widget? prefixIcon = widget.leftIcon;

    Widget? suffixIcon;
    if (widget.loading) {
      suffixIcon = const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (widget.obscureText) {
      suffixIcon = IconButton(
        icon: Icon(
          _isObscure ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: () {
          setState(() {
            _isObscure = !_isObscure;
          });
        },
      );
    } else if (widget.rightIcon != null) {
      suffixIcon = widget.rightIcon;
    }

    // Input decoration
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: appColors?.border ?? Colors.grey[300]!),
    );

    final errorBorder = border.copyWith(
      borderSide: const BorderSide(color: Colors.red),
    );

    final focusedBorder = border.copyWith(
      borderSide:
          BorderSide(color: appColors?.primary ?? Colors.blue, width: 2),
    );

    final input = TextField(
      controller: widget.controller,
      enabled: widget.enabled && !widget.loading,
      obscureText: _isObscure,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: TextStyle(color: appColors?.textPrimary ?? Colors.black),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.placeholder,
        errorText: widget.errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: widget.enabled ? Colors.transparent : Colors.grey[100],
      ),
    );

    if (widget.badges.isEmpty) {
      return input;
    }

    // Badges layout (below input)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        input,
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.badges.map((badge) {
            return Chip(
              label: Text(badge),
              onDeleted: widget.onBadgeRemove != null
                  ? () => widget.onBadgeRemove!(badge)
                  : null,
              backgroundColor: appColors?.primary?.withValues(alpha: 0.1),
              labelStyle: TextStyle(color: appColors?.primary),
              deleteIconColor: appColors?.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }
}
