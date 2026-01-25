class PassageSegment {
  const PassageSegment({
    required this.content,
    required this.translate,
  });

  factory PassageSegment.fromJson(Map<String, dynamic> json) {
    return PassageSegment(
      content: json['content'] as String? ?? '',
      translate: json['translate'] as String? ?? '',
    );
  }
  final String content;
  final String translate;

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'translate': translate,
    };
  }
}

class PassageData {
  const PassageData({
    required this.tid,
    required this.title,
    required this.segments,
  });

  factory PassageData.fromJson(Map<String, dynamic> json) {
    return PassageData(
      tid: json['tid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      segments: (json['segments'] as List<dynamic>? ?? [])
          .map((e) => PassageSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final String tid;
  final String title;
  final List<PassageSegment> segments;

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'title': title,
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }
}
