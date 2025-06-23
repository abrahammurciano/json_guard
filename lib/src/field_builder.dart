import "field_info.dart" show FieldInfo, Converter;
import "option.dart" show Option;

/// Builder class for creating field definitions with fluent configuration.
///
/// This class allows for chaining methods to create complex field definitions.
/// It supports defining optional fields and list fields as variations of existing fields.
class FieldBuilder<T, J> {
  /// The primary name of the field in the JSON.
  final String name;

  /// Alternative names for the field that will be checked if the primary name isn't found.
  final List<String> aliases;

  /// Function to convert the JSON value to the target type.
  final Converter<T, J> converter;

  /// Optional fallback value to use if the field is missing.
  final T? fallback;

  /// Optional function to build a fallback value if the field is missing.
  final T Function()? fallbackBuilder;

  /// Whether the field is optional (can be null).
  final bool isOptional;

  /// Creates a field builder with the specified properties.
  const FieldBuilder({
    required this.name,
    this.aliases = const [],
    required this.converter,
    this.fallback,
    this.fallbackBuilder,
    this.isOptional = false,
  });

  /// Makes the field optional, allowing null values.
  ///
  /// Returns a new field builder that accepts null values for the field.
  FieldBuilder<T?, J?> optional() {
    return FieldBuilder<T?, J?>(
      name: name,
      aliases: aliases,
      converter: (value, path, field) => value == null ? null : converter(value, path, field),
      fallback: fallback,
      fallbackBuilder: fallbackBuilder,
      isOptional: true,
    );
  }

  /// Makes the field a list of values of the original type.
  ///
  /// Returns a new field builder that expects a JSON array of items
  /// and applies the original converter to each item.
  FieldBuilder<List<T>, List<J>> list({List<T>? fallback}) {
    return FieldBuilder<List<T>, List<J>>(
      name: name,
      aliases: aliases,
      converter: (value, path, field) => [
        for (final (index, item) in value.indexed) converter(item, path[index], field),
      ],
      fallback: fallback,
      isOptional: isOptional,
    );
  }

  /// Makes the field a map of values of the original type.
  ///
  /// Returns a new field builder that expects a JSON object mapping
  /// and applies the original converter to each value.
  FieldBuilder<Map<String, T>, Map<String, J>> map({Map<String, T>? fallback}) {
    return FieldBuilder<Map<String, T>, Map<String, J>>(
      name: name,
      aliases: aliases,
      converter: (value, path, field) => {
        for (final entry in value.entries) entry.key: converter(entry.value, path / entry.key, field),
      },
      fallback: fallback,
      isOptional: isOptional,
    );
  }

  /// Creates a FieldInfo instance from this builder.
  ///
  /// This finalizes the field definition for use in a schema.
  FieldInfo<T, J> field() {
    return FieldInfo<T, J>(
      name,
      aliases: aliases,
      converter: converter,
      fallback: isOptional ? Option.value(fallback as T) : Option.maybe(fallback),
      fallbackBuilder: fallbackBuilder,
    );
  }
}
