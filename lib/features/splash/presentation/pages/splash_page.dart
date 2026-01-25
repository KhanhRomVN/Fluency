import 'package:fluency/core/constants/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToDashboard();
  }

  Future<void> _navigateToDashboard() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Use pushReplacement or go to prevent going back to splash
      GoRouter.of(context).go(RouteConstants.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Splash Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
