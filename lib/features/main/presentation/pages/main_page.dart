import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Course'),
          BottomNavigationBarItem(
              icon: Icon(Icons.star), label: 'Center'), // Placeholder icon
          BottomNavigationBarItem(
              icon: Icon(Icons.category), label: 'Extras'), // Temp placeholder
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
