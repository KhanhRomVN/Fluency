import 'dart:async';
import 'package:fluency/core/services/usage/daily_usage_repository.dart';
import 'package:flutter/widgets.dart';

class AppUsageService extends WidgetsBindingObserver {
  final DailyUsageRepository _repository;
  DateTime? _startTime;
  Timer? _periodicTimer;

  AppUsageService(this._repository);

  void startTracking() {
    _startTime = DateTime.now();
    WidgetsBinding.instance.addObserver(this);

    // Periodically save every minute to ensure data isn't lost on crash
    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _saveCurrentSession();
      _startTime = DateTime.now(); // Reset start time for next interval
    });
  }

  void _saveCurrentSession() {
    if (_startTime != null) {
      final now = DateTime.now();
      final minutes = now.difference(_startTime!).inMinutes;
      if (minutes > 0) {
        _repository.addMinutes(minutes);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentSession();
      _startTime = null;
    } else if (state == AppLifecycleState.resumed) {
      _startTime = DateTime.now();
    }
  }

  void stopTracking() {
    _saveCurrentSession();
    _periodicTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
