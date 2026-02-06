class VoiceModel {
  final String name;
  final String code;
  final String url;
  final String size;

  const VoiceModel({
    required this.name,
    required this.code,
    required this.url,
    required this.size,
  });
}

class DownloadState {
  final bool isDownloading;
  final int totalModels;
  final int downloadedModels;
  final String? currentModelName;

  DownloadState({
    required this.isDownloading,
    required this.totalModels,
    required this.downloadedModels,
    this.currentModelName,
  });

  double get progress => totalModels > 0 ? downloadedModels / totalModels : 0.0;

  bool get isCompleted => !isDownloading && downloadedModels >= totalModels;
}
