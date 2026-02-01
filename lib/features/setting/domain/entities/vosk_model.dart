class VoskModel {
  final String id;
  final String name;
  final String description;
  final int sizeInBytes;
  final String downloadUrl;
  final String fileName;

  const VoskModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeInBytes,
    required this.downloadUrl,
    required this.fileName,
  });

  String get sizeFormatted {
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  static const List<VoskModel> availableModels = [
    VoskModel(
      id: 'en-us-small',
      name: 'English (Small)',
      description: '41.2 MB - Optimized for speed',
      sizeInBytes: 43201331, // 41.2 MB approx
      downloadUrl:
          'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
      fileName: 'vosk-model-small-en-us-0.15',
    ),
  ];
}
