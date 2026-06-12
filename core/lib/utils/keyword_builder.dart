/// Builds the `keywords` array stored on design docs for Firestore-native
/// search (`array-contains` on a single query token).
///
/// Single source of truth for tokenization: the admin app uses it when
/// writing designs, and any future backfill script must produce identical
/// output. Contract: docs/integration/FIRESTORE_SCHEMA.md §7.
class KeywordBuilder {
  KeywordBuilder._();

  static const int maxKeywords = 30;
  static const int _minTokenLength = 2;

  /// Tokenizes title + categoryName + techniques + threadType into lowercase
  /// keywords: split on non-alphanumeric (Devanagari preserved for Hindi
  /// titles), deduped, tokens shorter than 2 chars dropped, capped at 30.
  static List<String> build({
    required String title,
    String? categoryName,
    List<String> techniques = const [],
    String? threadType,
  }) {
    final source = [
      title,
      if (categoryName != null) categoryName,
      ...techniques,
      if (threadType != null) threadType,
    ].join(' ');

    final tokens =
        source.toLowerCase().split(RegExp(r'[^a-z0-9ऀ-ॿ]+'));

    final seen = <String>{};
    final keywords = <String>[];
    for (final token in tokens) {
      if (token.length < _minTokenLength) continue;
      if (seen.add(token)) keywords.add(token);
      if (keywords.length >= maxKeywords) break;
    }
    return keywords;
  }
}
