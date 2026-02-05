enum SttProviderType {
  system,
}

extension SttProviderTypeExtension on SttProviderType {
  String get label {
    switch (this) {
      case SttProviderType.system:
        return 'System Default (Online/Offline)';
    }
  }

  String get description {
    switch (this) {
      case SttProviderType.system:
        return 'Uses Google/Apple speech services. May require internet.';
    }
  }
}
