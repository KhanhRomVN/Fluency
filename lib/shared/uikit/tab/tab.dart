import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class AppTabItem {
  final String label;
  final Widget content;
  final IconData? icon;

  const AppTabItem({
    required this.label,
    required this.content,
    this.icon,
  });
}

class AppTabs extends StatefulWidget {
  const AppTabs({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.isScrollable = false,
  });

  final List<AppTabItem> tabs;
  final int initialIndex;
  final bool isScrollable;

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: widget.isScrollable,
          labelColor: appColors?.primary ?? Colors.blue,
          unselectedLabelColor: appColors?.textSecondary ?? Colors.grey,
          indicatorColor: appColors?.primary ?? Colors.blue,
          tabs: widget.tabs.map((tab) {
            return Tab(
              text: tab.label,
              icon: tab.icon != null ? Icon(tab.icon) : null,
            );
          }).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabs.map((tab) => tab.content).toList(),
          ),
        ),
      ],
    );
  }
}
