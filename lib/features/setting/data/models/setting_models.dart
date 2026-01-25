import 'package:flutter/material.dart';

/// Represents a section in the settings page
class SettingSection {
  const SettingSection({
    required this.title,
    required this.items,
  });
  final String title;
  final List<SettingItem> items;
}

/// Represents an individual setting item
class SettingItem {
  const SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
}
