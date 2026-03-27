class SortUtils {
  /// Compares two strings using natural sort order (e.g., "2" comes before "10").
  static int naturalCompare(String a, String b) {
    final re = RegExp(r'(\d+)|(\D+)');
    final matchesA = re.allMatches(a.toLowerCase()).toList();
    final matchesB = re.allMatches(b.toLowerCase()).toList();

    final length =
        matchesA.length < matchesB.length ? matchesA.length : matchesB.length;

    for (var i = 0; i < length; i++) {
      final mA = matchesA[i].group(0)!;
      final mB = matchesB[i].group(0)!;

      final valA = int.tryParse(mA);
      final valB = int.tryParse(mB);

      if (valA != null && valB != null) {
        if (valA != valB) return valA.compareTo(valB);
      } else {
        if (mA != mB) return mA.compareTo(mB);
      }
    }

    return matchesA.length.compareTo(matchesB.length);
  }
}
