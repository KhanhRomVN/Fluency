class Dialogue {
  const Dialogue({
    required this.id,
    required this.original,
    required this.translation,
  });

  factory Dialogue.fromJson(Map<String, dynamic> json) {
    return Dialogue(
      id: json['id'] as String? ?? '',
      original: json['original'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
    );
  }
  final String id;
  final String original;
  final String translation;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original': original,
      'translation': translation,
    };
  }
}

class TranscriptTimestamps {
  const TranscriptTimestamps({
    required this.start,
    required this.end,
  });

  factory TranscriptTimestamps.fromJson(Map<String, dynamic> json) {
    return TranscriptTimestamps(
      start: json['start'] as String? ?? '00:00',
      end: json['end'] as String? ?? '00:00',
    );
  }
  final String start;
  final String end;

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }

  // Parse MM:SS to seconds
  int get startSeconds {
    final parts = start.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }

  int get endSeconds {
    final parts = end.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }
}

class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.speaker,
    required this.timestamps,
    required this.dialogues,
  });

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      id: json['id'] as int? ?? 0,
      speaker: json['speaker'] as String? ?? '',
      timestamps: TranscriptTimestamps.fromJson(
        json['timestamps'] as Map<String, dynamic>? ?? {},
      ),
      dialogues: (json['dialogues'] as List<dynamic>? ?? [])
          .map((e) => Dialogue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final int id;
  final String speaker;
  final TranscriptTimestamps timestamps;
  final List<Dialogue> dialogues;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speaker': speaker,
      'timestamps': timestamps.toJson(),
      'dialogues': dialogues.map((d) => d.toJson()).toList(),
    };
  }

  // Check if this segment is active at given time
  bool isActiveAt(double currentTime) {
    return currentTime >= timestamps.startSeconds &&
        currentTime < timestamps.endSeconds;
  }
}

class TranscriptData {
  const TranscriptData({
    required this.metadata,
    required this.transcript,
  });

  factory TranscriptData.fromJson(Map<String, dynamic> json) {
    return TranscriptData(
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      transcript: (json['transcript'] as List<dynamic>? ?? [])
          .map((e) => TranscriptSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final Map<String, dynamic> metadata;
  final List<TranscriptSegment> transcript;

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata,
      'transcript': transcript.map((s) => s.toJson()).toList(),
    };
  }
}
