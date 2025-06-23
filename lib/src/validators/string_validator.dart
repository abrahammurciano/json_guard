import "../exceptions.dart" show ValueValidationException, WrongJsonTypeException;
import "../field_info.dart" show FieldInfo;
import "../json_path.dart" show JsonPath;

/// Defines the case to convert a string to during validation.
enum StringCase {
  /// Convert the string to lowercase.
  lower,

  /// Convert the string to uppercase.
  upper;

  /// Converts a string to the specified case.
  String convert(String value) {
    return switch (this) {
      StringCase.lower => value.toLowerCase(),
      StringCase.upper => value.toUpperCase(),
    };
  }
}

/// Validator for converting and validating string values from JSON.
///
/// Supports validating string length, pattern matching, transforming case,
/// and restricting to a set of allowed values.
class StringValidator {
  /// The minimum allowed length of the string, if any.
  final int? minLength;

  /// The maximum allowed length of the string, if any.
  final int? maxLength;

  /// A regular expression that the string must match, if any.
  final RegExp? pattern;

  /// Whether to trim whitespace from the string before validation.
  final bool trim;

  /// A set of allowed string values, if any.
  final Set<String>? options;

  /// The case to convert the string to, if any.
  final StringCase? caseType;

  /// Whether to coerce the value to a string if it's not already.
  final bool coerce;

  /// Creates a string validator with the specified constraints.
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
  /// Throws a [ValueValidationException] if the value doesn't meet the constraints.
  String validate(dynamic value, JsonPath path, FieldInfo field) {
    if (!coerce && value is! String) {
      throw WrongJsonTypeException(value, expected: "String", field: field, path: path);
    }
    return _checkConstraints(value.toString(), path, field);
  }

  /// Applies transformations and checks that the string meets all constraints.
  String _checkConstraints(String value, JsonPath path, FieldInfo field) {
    value = trim ? value.trim() : value;
    value = caseType?.convert(value) ?? value;
    if (minLength != null && value.length < minLength!) {
      throw ValueValidationException(value, "String length must be at least $minLength", field: field, path: path);
    }
    if (maxLength != null && value.length > maxLength!) {
      throw ValueValidationException(value, "String length must be at most $maxLength", field: field, path: path);
    }
    if (pattern != null && !pattern!.hasMatch(value)) {
      throw ValueValidationException(value, "String must match the required pattern", field: field, path: path);
    }
    if (options != null && !options!.contains(value)) {
      throw ValueValidationException(value, "String must be one of: ${options!.join(', ')}", field: field, path: path);
    }
    return value;
  }
}
