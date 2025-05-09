
class Functions{
  /// Escapes strings to safely inject into JavaScript
  static String escapeJS(String value) {
    return value
      .replaceAll(r'\', r'\\')
      .replaceAll(r'"', r'\"')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\\n');
  }
}
