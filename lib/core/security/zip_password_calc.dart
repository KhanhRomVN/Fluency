class ZipPasswordCalc {
  // Obfuscated password components to avoid raw string in binary
  static const List<String> _p1 = ['F', 'l', 'u', 'e', 'n', 'c', 'y'];
  static const List<String> _p2 = ['C', 'o', 'u', 'r', 's', 'e'];
  static const List<String> _p3 = ['S', 'e', 'c', 'u', 'r', 'e'];
  static const List<String> _p4 = ['P', 'a', 'c', 'k', 'a', 'g', 'e'];
  static const String _p5 = r'_LongPassword_2024_!@#$%^&*()_+';

  /// Calculate the default password without using any plugins
  static String getDefaultPassword() {
    return '${_p1.join()}${_p2.join()}${_p3.join()}${_p4.join()}$_p5';
  }
}
