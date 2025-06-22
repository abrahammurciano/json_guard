import "../exceptions.dart" show ValueValidationException;
import "../field_info.dart" show FieldInfo;
import "../json_path.dart" show JsonPath;

/// Validator for converting and validating DateTime values from JSON.
///
/// Supports parsing dates from ISO8601 strings and numeric timestamps,
/// as well as validating that dates fall within a specified range.
class DateTimeValidator {
  /// The minimum allowed date and time, if any.
  final DateTime? min;

  /// The maximum allowed date and time, if any.
  final DateTime? max;

  /// Whether to allow parsing dates from ISO8601 strings.
  final bool allowIso8601;

  /// Whether to allow parsing dates from numeric timestamps.
  final bool allowTimestamp;

  /// Creates a DateTime validator with the specified constraints.
  DateTimeValidator({this.min, this.max, this.allowIso8601 = true, this.allowTimestamp = true});

  /// Validates and converts a value to a DateTime.
  ///
  /// Throws a [ValueValidationException] if the value cannot be converted
  /// or if it doesn't meet the constraints.
  DateTime validate(dynamic value, JsonPath path, FieldInfo field) {
    return _checkConstraints(_convert(value, path, field), path, field);
  }

  /// Checks that the DateTime value meets the min/max constraints.
  DateTime _checkConstraints(DateTime dateValue, JsonPath path, FieldInfo field) {
    if (min != null && dateValue.isBefore(min!)) {
      throw ValueValidationException(
        dateValue.toString(),
        "Date must be at or after ${min!.toString()}",
        field: field,
        path: path,
      );
    }

    if (max != null && dateValue.isAfter(max!)) {
      throw ValueValidationException(
        dateValue.toString(),
        "Date must be at or before ${max!.toString()}",
        field: field,
        path: path,
      );
    }

    return dateValue;
  }

  /// Converts a value to a DateTime based on its type.
  DateTime _convert(dynamic value, JsonPath path, FieldInfo field) {
    return switch (value) {
      String() => _fromString(value, path, field),
      num() => _fromTimestamp(value, path, field),
      DateTime() => value,
      _ => throw ValueValidationException(
        value,
        "Cannot convert ${value.runtimeType} to DateTime",
        field: field,
        path: path,
      ),
    };
  }

  /// Attempts to parse a DateTime from a string.
  DateTime _fromString(String value, JsonPath path, FieldInfo field) {
    if (allowIso8601) {
      final result = DateTime.tryParse(value);
      if (result != null) {
        return result;
      }
    }
    final result = num.tryParse(value);
    if (result == null) {
      throw ValueValidationException(value, "Failed to parse datetime from string", field: field, path: path);
    }
    return _fromTimestamp(result, path, field);
  }

  /// Converts a timestamp to a DateTime.
  DateTime _fromTimestamp(num timestamp, JsonPath path, FieldInfo field) {
    if (!allowTimestamp) {
      throw ValueValidationException(timestamp, "Timestamps are not allowed for this field", field: field, path: path);
    }
    return DateTime.fromMicrosecondsSinceEpoch((timestamp * 1_000_000).toInt());
  }
}
