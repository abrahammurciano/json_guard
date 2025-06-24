/// Validates and converts string values to enum values.
///
/// The EnumValidator maps string values from JSON to typed enum values using a
/// provided mapping dictionary. It supports both case-sensitive and case-insensitive
/// matching to handle variations in API responses.
///
/// This validator is used by [Field.enumeration] to create fields that work with
/// enum values.
class EnumValidator<E> {
  /// Mapping from string values to enum values.
  ///
  /// This dictionary defines the valid string values and their corresponding
  /// enum values. If case-insensitive matching is enabled, the keys in this
  /// map will be normalized to lowercase.
  final Map<String, E> values;

  /// Whether string matching should be case-sensitive.
  ///
  /// When true, string matching is exact (e.g., "Active" != "active").
  /// When false, matching ignores case (e.g., "Active" == "active").
  final bool caseSensitive;

  /// Creates an enum validator with the specified value mapping.
  ///
  /// Parameters:
  /// - [values]: Dictionary mapping string values to enum values
  /// - [caseSensitive]: Whether string matching should be case-sensitive
  ///
  /// If [caseSensitive] is false (the default), all keys in the values map
  /// will be converted to lowercase for matching.
  EnumValidator({required Map<String, E> values, this.caseSensitive = false})
    : values = caseSensitive ? values : {for (final entry in values.entries) entry.key.toLowerCase(): entry.value};

  /// Validates a string and converts it to the corresponding enum value.
  ///
  /// This method looks up the input string in the values map and returns
  /// the corresponding enum value if found.
  ///
  /// Parameters:
  /// - [value]: The string value to validate and convert
  ///
  /// Returns the matching enum value.
  ///
  /// Throws an ArgumentError if:
  /// - The input is not a string
  /// - The string doesn't match any key in the values map
  E validate(Object? value) {
    value = value as String;
    final key = caseSensitive ? value : value.toLowerCase();
    final result = values[key];
    if (result == null) {
      throw ArgumentError(
        "Value must be one of ${values.keys.join(', ')}${caseSensitive ? '' : ' (case-insensitive)'}",
      );
    }
    return result;
  }
}
