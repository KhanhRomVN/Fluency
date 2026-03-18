import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundEffectProvider extends ChangeNotifier {
  static const String _soundEnabledKey = 'sfx_enabled';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final SharedPreferences _prefs;
  bool _isSoundEnabled = true;

  SoundEffectProvider(this._prefs) {
    _isSoundEnabled = _prefs.getBool(_soundEnabledKey) ?? true;
  }

  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    await _prefs.setBool(_soundEnabledKey, enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playCorrect() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.stop(); // Stop current sound if playing
      await _audioPlayer.play(AssetSource('sound-effect/correct.wav'));
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error playing correct sound: $e');
    }
  }

  Future<void> playWrong() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.stop(); // Stop current sound if playing
      await _audioPlayer.play(AssetSource('sound-effect/wrong.wav'));
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error playing wrong sound: $e');
    }
  }
}
