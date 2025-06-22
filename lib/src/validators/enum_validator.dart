import "../exceptions.dart" show ValueValidationException;
import "../field_info.dart" show FieldInfo;
import "../json_path.dart" show JsonPath;

/// Validator for converting string values to enum values.
///
/// Maps string values from JSON to enum values using a provided mapping.
/// Supports case-insensitive matching.
class EnumValidator<E> {
  /// Mapping from string values to enum values.
  final Map<String, E> values;

  /// Whether string matching should be case-sensitive.
  final bool caseSensitive;

  /// Creates an enum validator with the specified value mapping.
  ///
  /// If [caseSensitive] is false (the default), all keys in the values map
  /// will be converted to lowercase for matching.
  EnumValidator({required Map<String, E> values, this.caseSensitive = false})
    : values = caseSensitive ? values : {for (final entry in values.entries) entry.key.toLowerCase(): entry.value};

  /// Validates a string and converts it to the corresponding enum value.
  ///
  /// Throws a [ValueValidationException] if the string doesn't match any
  /// of the allowed values.
  E validate(String value, JsonPath path, FieldInfo field) {
    final result = values[caseSensitive ? value : value.toLowerCase()];
    if (result == null) {
      throw ValueValidationException(
        value,
        "Value must be one of: ${values.keys.join(', ')}",
        field: field,
        path: path,
      );
    }
    return result;
  }
}
