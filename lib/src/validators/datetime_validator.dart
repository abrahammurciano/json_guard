/// Validates and converts values to DateTime objects with optional range constraints.
///
/// The DateTimeValidator supports parsing dates from multiple formats:
/// - ISO8601 strings (e.g., "2023-06-15T14:30:00Z")
/// - Numeric timestamps (e.g., 1623767400)
/// - Existing DateTime objects
///
/// It also validates that dates fall within a specified range if min/max constraints are provided.
///
/// This validator is used by [Field.datetime] to create fields that work with date and time values.
class DateTimeValidator {
  /// The minimum allowed date and time, if any.
  ///
  /// If specified, dates earlier than this will fail validation.
  final DateTime? min;

  /// The maximum allowed date and time, if any.
  ///
  /// If specified, dates later than this will fail validation.
  final DateTime? max;

  /// Whether to allow parsing dates from ISO8601 strings.
  ///
  /// When true, string values will be parsed as ISO8601 dates.
  final bool allowIso8601;

  /// Whether to allow parsing dates from numeric timestamps.
  ///
  /// When true, numeric values will be interpreted as seconds since the Unix epoch.
  final bool allowTimestamp;

  /// Creates a DateTime validator with the specified constraints.
  ///
  /// Parameters:
  /// - [min]: Optional minimum allowed date and time (inclusive)
  /// - [max]: Optional maximum allowed date and time (inclusive)
  /// - [allowIso8601]: Whether to allow parsing ISO8601 strings
  /// - [allowTimestamp]: Whether to allow parsing numeric timestamps
  DateTimeValidator({this.min, this.max, this.allowIso8601 = true, this.allowTimestamp = true});

  /// Validates and converts a value to a DateTime.
  ///
  /// This method handles:
  /// 1. Converting the value to a DateTime based on its type
  /// 2. Checking that the DateTime falls within the specified range
  ///
  /// Parameters:
  /// - [value]: The value to validate and convert
  ///
  /// Returns the validated DateTime value.
  ///
  /// Throws an ArgumentError if:
  /// - The value cannot be converted to a DateTime
  /// - The DateTime is earlier than [min] (if specified)
  /// - The DateTime is later than [max] (if specified)
  DateTime validate(Object? value) {
    return _checkConstraints(_convert(value));
  }

  /// Checks that the DateTime value meets the min/max constraints.
  ///
  /// Parameters:
  /// - [dateValue]: The DateTime value to validate
  ///
  /// Returns the validated DateTime value.
  ///
  /// Throws an ArgumentError if:
  /// - The DateTime is earlier than [min] (if specified)
  /// - The DateTime is later than [max] (if specified)
  DateTime _checkConstraints(DateTime dateValue) {
    if (min != null && dateValue.isBefore(min!)) {
      throw ArgumentError("Date must be at or after ${min!.toString()}");
    }

    if (max != null && dateValue.isAfter(max!)) {
      throw ArgumentError("Date must be at or before ${max!.toString()}");
    }

    return dateValue;
  }

  /// Converts a value to a DateTime based on its type.
  ///
  /// Handles the following conversions:
  /// - String: parsed as ISO8601 or timestamp string
  /// - num: converted from seconds since epoch
  /// - DateTime: used as is
  ///
  /// Parameters:
  /// - [value]: The value to convert to a DateTime
  ///
  /// Returns the converted DateTime value.
  ///
  /// Throws an ArgumentError if the value cannot be converted.
  DateTime _convert(Object? value) {
    return switch (value) {
      String() => _fromString(value),
      num() => _fromTimestamp(value),
      DateTime() => value,
      _ => throw ArgumentError("Cannot convert to DateTime"),
    };
  }

  /// Attempts to parse a DateTime from a string.
  ///
  /// This method tries multiple approaches:
  /// 1. If allowIso8601 is true, tries to parse as an ISO8601 string
  /// 2. If that fails, tries to parse as a numeric timestamp string
  ///
  /// Parameters:
  /// - [value]: The string to parse
  ///
  /// Returns the parsed DateTime value.
  ///
  /// Throws an ArgumentError if the string cannot be parsed.
  DateTime _fromString(String value) {
    if (allowIso8601) {
      final result = DateTime.tryParse(value);
      if (result != null) {
        return result;
      }
    }
    final result = num.tryParse(value);
    if (result == null) {
      throw ArgumentError("Failed to parse datetime");
    }
    return _fromTimestamp(result);
  }

  /// Converts a timestamp to a DateTime.
  ///
  /// The timestamp is interpreted as seconds since the Unix epoch.
  ///
  /// Parameters:
  /// - [timestamp]: The timestamp to convert
  ///
  /// Returns the converted DateTime value.
  ///
  /// Throws an ArgumentError if timestamps are not allowed.
  DateTime _fromTimestamp(num timestamp) {
    if (!allowTimestamp) {
      throw ArgumentError("Timestamps are not allowed for this field");
    }
    return DateTime.fromMicrosecondsSinceEpoch((timestamp * 1_000_000).toInt());
  }
}
