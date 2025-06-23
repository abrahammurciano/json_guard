import "../exceptions.dart" show ValueValidationException, WrongJsonTypeException;
import "../field_info.dart" show FieldInfo;
import "../json_path.dart" show JsonPath;

/// Validator for converting and validating integer values from JSON.
///
/// Supports converting from strings and doubles, and validating
/// that values fall within a specified range.
class IntegerValidator {
  /// The minimum allowed value, if any.
  final int? min;

  /// The maximum allowed value, if any.
  final int? max;

  /// Creates an integer validator with the specified constraints.
  IntegerValidator({this.min, this.max});

  /// Validates and converts a value to an integer.
  ///
  /// Throws exceptions if the value cannot be converted or if it
  /// doesn't meet the constraints.
  int validate(dynamic value, JsonPath path, FieldInfo field) {
    return _checkConstraints(_convert(value, path, field), path, field);
  }

  /// Converts a value to an integer based on its type.
  int _convert(dynamic value, JsonPath path, FieldInfo field) {
    return switch (value) {
      int() => value,
      double() => value.floor(),
      String() => _parseString(value, path, field),
      _ => throw WrongJsonTypeException(value, expected: "int, double, or String", field: field, path: path),
    };
  }

  /// Attempts to parse an integer from a string.
  ///
  /// First tries to parse as an integer directly, then falls back to
  /// parsing as a double and flooring the result.
  int _parseString(String value, JsonPath path, FieldInfo field) {
    try {
      return int.parse(value);
    } catch (_) {
      try {
        return double.parse(value).floor();
      } catch (_) {
        throw ValueValidationException(value, "Failed to parse to integer", field: field, path: path);
      }
    }
  }

  /// Checks that the integer value meets the min/max constraints.
  int _checkConstraints(int intValue, JsonPath path, FieldInfo field) {
    if (min != null && intValue < min!) {
      throw ValueValidationException(intValue, "Value must be at least $min", field: field, path: path);
    }
    if (max != null && intValue > max!) {
      throw ValueValidationException(intValue, "Value must be at most $max", field: field, path: path);
    }
    return intValue;
  }
}
