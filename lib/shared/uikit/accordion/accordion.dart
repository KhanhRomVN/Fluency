import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/shared/uikit/divider/divider.dart';
import 'package:flutter/material.dart';

enum AccordionType { single, multiple }

class Accordion extends StatefulWidget {
  const Accordion({
    super.key,
    required this.children,
    this.type = AccordionType.single,
    this.collapsible = true,
  });

  final List<Widget> children;
  final AccordionType type;
  final bool collapsible;

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> {
  final Set<String> _openItems = {};

  void toggleItem(String value) {
    setState(() {
      if (widget.type == AccordionType.single) {
        if (_openItems.contains(value) && widget.collapsible) {
          _openItems.clear();
        } else {
          _openItems.clear();
          _openItems.add(value);
        }
      } else {
        if (_openItems.contains(value)) {
          _openItems.remove(value);
        } else {
          _openItems.add(value);
        }
      }
    });
  }

  bool isOpen(String value) => _openItems.contains(value);

  @override
  Widget build(BuildContext context) {
    return _AccordionInherited(
      state: this,
      child: Column(
        children: widget.children,
      ),
    );
  }
}

class _AccordionInherited extends InheritedWidget {
  const _AccordionInherited({
    required this.state,
    required super.child,
  });

  final _AccordionState state;

  static _AccordionState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AccordionInherited>()
        ?.state;
  }

  @override
  bool updateShouldNotify(_AccordionInherited oldWidget) {
    return true; // Simple, rebuild always when state might change (though setstate handles it)
  }
}

class AccordionItem extends StatelessWidget {
  const AccordionItem({
    super.key,
    required this.value,
    required this.children,
  });

  final String value;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // In React, Divider is hidden for the first item.
    // Here we can try to inspect index if needed, but Column doesn't pass index.
    // We'll add Divider at the bottom or top? React adds it at the top with "first:hidden"
    // Using a simpler approach: Divider between items.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider(), // Logic for first item hidden is tricky without index
        // For simplicity, we assume parent column handles dividers or we put one at top effectively
        const AppDivider(thickness: DividerThickness.thin),
        _AccordionItemInherited(
          value: value,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _AccordionItemInherited extends InheritedWidget {
  const _AccordionItemInherited({
    required this.value,
    required super.child,
  });

  final String value;

  static String? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AccordionItemInherited>()
        ?.value;
  }

  @override
  bool updateShouldNotify(_AccordionItemInherited oldWidget) {
    return value != oldWidget.value;
  }
}

class AccordionTrigger extends StatelessWidget {
  const AccordionTrigger({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accordionState = _AccordionInherited.of(context);
    final itemValue = _AccordionItemInherited.of(context);

    if (accordionState == null || itemValue == null) {
      return child;
    }

    final isOpen = accordionState.isOpen(itemValue);

    return InkWell(
      onTap: () => accordionState.toggleItem(itemValue),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: child),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class AccordionContent extends StatelessWidget {
  const AccordionContent({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accordionState = _AccordionInherited.of(context);
    final itemValue = _AccordionItemInherited.of(context);

    final isOpen = accordionState?.isOpen(itemValue ?? '') ?? false;

    return AnimatedCrossFade(
      firstChild: Container(),
      secondChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
      crossFadeState:
          isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }
}
