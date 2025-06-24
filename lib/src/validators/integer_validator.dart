/// Validates and converts values to integers with optional range constraints.
///
/// The IntegerValidator is responsible for:
/// - Converting values from various types (int, double, String) to integers
/// - Validating that integer values fall within a specified range
/// - Providing clear error messages for validation failures
///
/// This validator is used by [Field.integer] to create fields that work with integer values.
class IntegerValidator {
  /// The minimum allowed value, if any.
  ///
  /// If specified, values less than this will fail validation.
  final int? min;

  /// The maximum allowed value, if any.
  ///
  /// If specified, values greater than this will fail validation.
  final int? max;

  /// Creates an integer validator with the specified constraints.
  ///
  /// Parameters:
  /// - [min]: Optional minimum allowed value (inclusive)
  /// - [max]: Optional maximum allowed value (inclusive)
  IntegerValidator({this.min, this.max});

  /// Validates and converts a value to an integer.
  ///
  /// This method handles:
  /// 1. Converting the value to an integer based on its type
  /// 2. Checking that the integer falls within the specified range
  ///
  /// Parameters:
  /// - [value]: The value to validate and convert
  ///
  /// Returns the validated integer value.
  ///
  /// Throws an ArgumentError if:
  /// - The value cannot be converted to an integer
  /// - The integer is less than [min] (if specified)
  /// - The integer is greater than [max] (if specified)
  int validate(Object? value) => _checkConstraints(_convert(value));

  /// Converts a value to an integer based on its type.
  ///
  /// Handles the following conversions:
  /// - int: used as is
  /// - double: converted using floor() to round down to nearest integer
  /// - String: parsed as an integer or as a double and then floored
  ///
  /// Parameters:
  /// - [value]: The value to convert to an integer
  ///
  /// Returns the converted integer value.
  ///
  /// Throws an ArgumentError if the value cannot be converted.
  int _convert(Object? value) {
    return switch (value) {
      int() => value,
      double() => value.floor(),
      String() => _parseString(value),
      _ => throw ArgumentError("Expected type int, double, or String"),
    };
  }

  /// Attempts to parse an integer from a string.
  ///
  /// This method tries multiple approaches:
  /// 1. First tries to parse as an integer directly
  /// 2. If that fails, tries to parse as a double and floor the result
  ///
  /// Parameters:
  /// - [value]: The string to parse
  ///
  /// Returns the parsed integer value.
  ///
  /// Throws an ArgumentError if the string cannot be parsed as a number.
  int _parseString(String value) {
    try {
      return int.parse(value);
    } catch (_) {
      try {
        return double.parse(value).floor();
      } catch (_) {
        throw ArgumentError("Failed to parse integer");
      }
    }
  }

  /// Checks that the integer value meets the min/max constraints.
  ///
  /// Parameters:
  /// - [value]: The integer value to validate
  ///
  /// Returns the validated integer value.
  ///
  /// Throws an ArgumentError if:
  /// - The integer is less than [min] (if specified)
  /// - The integer is greater than [max] (if specified)
  int _checkConstraints(int value) {
    if (min != null && value < min!) {
      throw ArgumentError("Value must be at least $min");
    }
    if (max != null && value > max!) {
      throw ArgumentError("Value must be at most $max");
    }
    return value;
  }
}
