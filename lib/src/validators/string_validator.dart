/// Defines the case transformation to apply to a string during validation.
///
/// This enum is used with [StringValidator] to convert strings to a specific case format during validation.
enum StringCase {
  /// Convert the string to lowercase.
  ///
  /// For example, "Hello World" becomes "hello world".
  lower,

  /// Convert the string to uppercase.
  ///
  /// For example, "Hello World" becomes "HELLO WORLD".
  upper;

  /// Converts a string to the specified case.
  ///
  /// Parameters:
  /// - [value]: The string to convert
  ///
  /// Returns the string converted to the specified case.
  String convert(String value) {
    return switch (this) {
      StringCase.lower => value.toLowerCase(),
      StringCase.upper => value.toUpperCase(),
    };
  }
}

/// Validates and transforms string values from JSON.
///
/// The StringValidator provides multiple ways to validate string values:
/// - Length constraints (minimum and maximum length)
/// - Pattern matching with regular expressions
/// - Case transformations (lower or upper)
/// - Whitespace trimming
/// - Restricting to a set of allowed values
/// - Type coercion from non-string values
///
/// This validator is used by [Field.string] to create string fields with various validation rules.
class StringValidator {
  /// The minimum allowed length of the string, if any.
  ///
  /// If specified, strings shorter than this length will fail validation.
  final int? minLength;

  /// The maximum allowed length of the string, if any.
  ///
  /// If specified, strings longer than this length will fail validation.
  final int? maxLength;

  /// A regular expression that the string must match, if any.
  ///
  /// If specified, strings that don't match this pattern will fail validation.
  final RegExp? pattern;

  /// Whether to trim whitespace from the string before validation.
  ///
  /// When true, leading and trailing whitespace is removed before applying other validations.
  final bool trim;

  /// A set of allowed string values, if any.
  ///
  /// If specified, strings not in this set will fail validation.
  final Set<String>? options;

  /// The case to convert the string to, if any.
  ///
  /// If specified, the string is converted to the specified case before validation.
  final StringCase? caseType;

  /// Whether to coerce non-string values to strings.
  ///
  /// When true, non-string values are converted to strings using toString().
  /// When false, non-string values cause validation to fail.
  final bool coerce;

  /// Creates a string validator with the specified constraints.
  ///
  /// Parameters:
  /// - [minLength]: The minimum allowed length of the string
  /// - [maxLength]: The maximum allowed length of the string
  /// - [pattern]: A regular expression the string must match
  /// - [trim]: Whether to trim whitespace before validation
  /// - [options]: A set of allowed string values
  /// - [caseType]: The case to convert the string to
  /// - [coerce]: Whether to coerce non-string values to strings
  StringValidator({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.trim = false,
    this.options,
    this.caseType,
    this.coerce = false,
  });

  /// Validates and converts a value to a string.
  ///
  /// This method checks that:
  /// 1. The value is a string (or can be coerced to one if coerce is true)
  /// 2. The string meets all specified constraints (length, pattern, etc.)
  ///
  /// Parameters:
  /// - [value]: The value to validate and convert
  ///
  /// Returns the validated string, possibly with transformations applied.
  ///
  /// Throws a TypeError if:
  /// - The value is not a string and coerce is false
  ///
  /// Throws an ArgumentError if:
  /// - The string fails any validation constraint
  String validate(Object? value) => _checkConstraints(coerce ? value.toString() : value as String);

  /// Applies transformations and checks that the string meets all constraints.
  ///
  /// This internal method handles:
  /// 1. Trimming whitespace if requested
  /// 2. Converting to the specified case if requested
  /// 3. Checking length constraints
  /// 4. Checking pattern matching
  /// 5. Checking allowed values
  ///
  /// Parameters:
  /// - [value]: The string to validate
  ///
  /// Returns the validated and transformed string.
  ///
  /// Throws an ArgumentError if the string fails any validation constraint.
  String _checkConstraints(String value) {
    value = trim ? value.trim() : value;
    value = caseType?.convert(value) ?? value;
    if (minLength != null && value.length < minLength!) {
      throw ArgumentError("String length must be at least $minLength");
    }
    if (maxLength != null && value.length > maxLength!) {
      throw ArgumentError("String length must be at most $maxLength");
    }
    if (pattern != null && !pattern!.hasMatch(value)) {
      throw ArgumentError("String must match the required pattern");
    }
    if (options != null && !options!.contains(value)) {
      throw ArgumentError("String must be one of: ${options!.join(', ')}");
    }
    return value;
  }
}
