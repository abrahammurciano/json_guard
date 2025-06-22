import "exceptions.dart" show JsonTypeException, FieldMissingException, ArgumentErrorValidationException;
import "extensions.dart" show ExtendIterable;
import "json_path.dart" show JsonPath;
import "option.dart" show Option;

/// Function type for converting a JSON value of type J to a Dart value of type T.
///
/// The converter is provided with the raw value, the JSON path, and field information.
typedef Converter<T, J> = T Function(J value, JsonPath path, FieldInfo field);

/// Defines metadata for a field in a schema, including how to extract and convert its value from JSON.
class FieldInfo<T, J> {
  /// The primary name of the field in the JSON.
  final String name;

  /// Alternative names for the field that will be checked if the primary name isn't found.
  final List<String> aliases;

  /// Function to convert the JSON value to the target type.
  final Converter<T, J> converter;

  /// Optional fallback value to use if the field is missing.
  final Option<T> fallback;

  /// Optional function to build a fallback value if the field is missing.
  final T Function()? fallbackBuilder;

  /// Creates a field definition with the specified properties.
  ///
  /// Either [fallback] or [fallbackBuilder] can be provided, but not both.
  FieldInfo(
    this.name, {
    this.aliases = const [],
    required this.converter,
    this.fallback = const Option.empty(),
    this.fallbackBuilder,
  }) : assert(
         fallback.isEmpty || fallbackBuilder == null,
         "Either fallback or fallbackProvider must be provided, not both.",
       );

  /// Extracts, validates, and converts the field's value from the JSON object.
  ///
  /// Throws exceptions if the field is missing and no fallback is available,
  /// or if the value is of the wrong type, or if validation fails.
  T value(Map<String, dynamic> json, JsonPath path) {
    return _jsonValue(json).when(
      empty: () => _fallback(json, path),
      value: (value) {
        if (value is! J) {
          throw JsonTypeException(value, expected: J.toString(), field: this, path: path);
        }
        try {
          return converter(value, path, this);
        } on ArgumentError catch (e) {
          throw ArgumentErrorValidationException(value, e.message.toString(), field: this, path: path);
        }
      },
    );
  }

  /// Attempts to find the field's value in the JSON using the primary name and aliases.
  Option<dynamic> _jsonValue(Map<String, dynamic> json) {
    final key = [name, ...aliases].firstWhereOrNull((key) => json.containsKey(key));
    return key == null ? const Option.empty() : Option.value(json[key]);
  }

  /// Provides the fallback value or throws an exception if the field is required.
  T _fallback(Map<String, dynamic> json, JsonPath path) {
    return fallback.or(
      () => fallbackBuilder == null ? throw FieldMissingException(json, path: path, field: this) : fallbackBuilder!(),
    );
  }
}
