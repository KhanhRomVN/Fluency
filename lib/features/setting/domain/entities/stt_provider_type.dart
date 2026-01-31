enum SttProviderType {
  system,
  vosk,
}

extension SttProviderTypeExtension on SttProviderType {
  String get label {
    switch (this) {
      case SttProviderType.system:
        return 'System Default (Online/Offline)';
      case SttProviderType.vosk:
        return 'Offline Model (Vosk)';
    }
  }

  String get description {
    switch (this) {
      case SttProviderType.system:
        return 'Uses Google/Apple speech services. May require internet.';
      case SttProviderType.vosk:
        return 'Runs completely offline. Higher privacy and reliability.';
    }
  }
}
