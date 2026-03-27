abstract class TtsService {
  /// Initialize the service
  Future<void> initialize();

  /// Speak the given [text] with optional [speed] and [pitch]
  Future<void> speak(String text, {double speed = 1.0, double pitch = 1.0});

  /// Stop speaking
  Future<void> stop();

  /// Get the Stream of TTS state (playing, stopped, etc)
  Stream<TtsState> get stateStream;

  /// Get the service identifier (e.g. 'System', 'Piper')
  String get serviceId;

  /// Dispose resources
  void dispose();
}

enum TtsState {
  playing,
  stopped,
  paused,
  continued,
}
