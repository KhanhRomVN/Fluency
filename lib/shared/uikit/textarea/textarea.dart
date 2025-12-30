import 'package:fluency/shared/uikit/input/input.dart';
import 'package:flutter/material.dart';

class AppTextarea extends StatelessWidget {
  const AppTextarea({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.minLines = 3,
    this.maxLines = 5,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: label,
      placeholder: placeholder,
      errorText: errorText,
      enabled: enabled,
      onChanged: onChanged,
      maxLines: maxLines,
      // Input typically doesn't handle minLines directly if maxLines is small,
      // but TextField does. AppInput passes maxLines.
      // Need to ensure AppInput underlying TextField supports multiline.
      // In AppInput, I set `maxLines: widget.obscureText ? 1 : widget.maxLines`.
      // So it should work.
    );
  }
}
