abstract class TtsService {
  /// Initialize the service
  Future<void> initialize();

  /// Speak the given [text]
  Future<void> speak(String text);

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
