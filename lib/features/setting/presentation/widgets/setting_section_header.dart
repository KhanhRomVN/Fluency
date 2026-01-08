import 'package:flutter/material.dart';

/// Custom widget for setting section headers
class SettingSectionHeader extends StatelessWidget {
  final String title;

  const SettingSectionHeader({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
      ),
    );
  }
}
