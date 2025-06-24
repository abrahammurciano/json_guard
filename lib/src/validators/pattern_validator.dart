/// Validates and converts string patterns to RegExp objects.
///
/// The PatternValidator is responsible for:
/// - Validating that a value contains a valid regular expression pattern
/// - Converting the pattern string to a RegExp object
/// - Configuring RegExp options like case sensitivity and multiline mode
/// - Optionally adding anchors to make the pattern match the full string
///
/// This validator is used by [Field.pattern] to create fields that work with
/// regular expressions.
class PatternValidator {
  /// Whether to anchor the pattern with ^ and $ to match full strings.
  ///
  /// When true, the pattern is modified to match the entire string
  /// by adding ^ at the beginning and $ at the end if they're not already present.
  final bool full;

  /// Whether to enable multi-line mode for the RegExp.
  ///
  /// When true, the ^ and $ anchors match at the beginning and end of each line.
  /// When false, they match only at the beginning and end of the entire string.
  final bool multiLine;

  /// Whether the RegExp should be case-sensitive.
  ///
  /// When true, matches are case-sensitive (e.g., 'a' does not match 'A').
  /// When false, matches are case-insensitive (e.g., 'a' matches 'A').
  final bool caseSensitive;

  /// Whether to enable Unicode support in the RegExp.
  ///
  /// When true, Unicode features like character classes (\p{...}) are supported.
  final bool unicode;

  /// Creates a pattern validator with the specified options.
  ///
  /// Parameters:
  /// - [full]: Whether to anchor the pattern to match full strings
  /// - [multiLine]: Whether to enable multi-line mode
  /// - [caseSensitive]: Whether matches should be case-sensitive
  /// - [unicode]: Whether to enable Unicode support
  PatternValidator({this.full = false, this.multiLine = false, this.caseSensitive = true, this.unicode = false});

  /// Validates and converts a pattern string to a RegExp object.
  ///
  /// Parameters:
  /// - [value]: The string pattern to validate and convert
  ///
  /// Returns a RegExp object configured with the specified options.
  ///
  /// Throws an ArgumentError if the pattern is invalid.
  RegExp validate(Object? value) {
    final withAnchors = _withAnchors(value as String);
    try {
      return RegExp(withAnchors, multiLine: multiLine, caseSensitive: caseSensitive, unicode: unicode);
    } catch (e) {
      throw ArgumentError("Invalid regular expression: $e");
    }
  }

  /// Adds anchors to a pattern if necessary to match full strings.
  ///
  /// If [full] is true, adds ^ at the beginning and $ at the end of the pattern
  /// if they're not already present.
  ///
  /// Parameters:
  /// - [pattern]: The pattern string to modify
  ///
  /// Returns the pattern with anchors added if necessary.
  String _withAnchors(String pattern) {
    if (!full) {
      return pattern;
    }
    if (!pattern.startsWith("^")) {
      pattern = "^$pattern";
    }
    if (!pattern.endsWith("\$")) {
      pattern = "$pattern\$";
    }
    return pattern;
  }
}
