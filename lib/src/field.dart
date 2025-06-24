import "json_path.dart" show JsonPath;
import "schema.dart" show Schema;
import "validator.dart" show Validator;
import "validators/string_validator.dart" show StringCase;

typedef Converter<T> = T Function(dynamic value, JsonPath path);

/// Defines a field within a JSON schema with validation rules and transformation logic.
///
/// The Field class is the core building block for defining JSON schemas. Each field represents a property in a JSON object and specifies:
///
/// - How to locate the property in the JSON (using a name and optional aliases)
/// - How to validate the property's value (using type-specific validators)
/// - How to convert the value to the desired Dart type
/// - What to do if the property is missing (provide a fallback or report an error)
///
/// Fields are created using various factory methods that provide type-specific validation, such as [Field.string], [Field.integer], [Field.datetime], etc.
///
/// Example:
/// ```dart
/// final nameField = Field.string('name', minLength: 2, maxLength: 100);
/// final ageField = Field.integer('age', min: 0, max: 120);
/// final statusField = Field.enumeration('status', values: {
///   'active': Status.active,
///   'inactive': Status.inactive,
/// });
/// ```
class Field<T> {
  /// The primary name of the field in the JSON.
  ///
  /// This is the key that will be looked for in the JSON object.
  final String name;

  /// Alternative names for the field that will be checked if the primary name isn't found.
  ///
  /// This is useful for handling changes in API field names or supporting multiple naming conventions (e.g., snake_case and camelCase).
  final List<String> aliases;

  /// The validator that converts and validates the JSON value.
  ///
  /// This validator handles:
  /// - Converting the raw JSON value to the target type T
  /// - Validating that the value meets any constraints
  /// - Providing fallback values when appropriate
  final Validator<T> validator;

  /// Creates a field with the specified properties.
  ///
  /// This internal constructor is used by the various factory methods to create fields with specific validation rules.
  const Field._internal({required this.name, this.aliases = const [], required this.validator});

  /// Makes the field optional, allowing null values.
  ///
  /// By default, fields are required and will cause validation errors if missing. Calling this method makes the field accept null values or be absent from the JSON.
  ///
  /// Returns a new field of type T? that accepts null values or can be missing from the input.
  ///
  /// Example:
  /// ```dart
  /// final optionalAge = Field.integer('age', min: 0).optional();
  /// ```
  Field<T?> optional() => Field<T?>._internal(name: name, aliases: aliases, validator: validator.optional());

  /// Makes the field a list of values of the original type.
  ///
  /// This transforms a field of type T to a field of type [List<T>], expecting a JSON array where each item is validated against the original field's rules.
  ///
  /// Parameters:
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a new field that validates lists of the original type.
  ///
  /// Example:
  /// ```dart
  /// final tagsField = Field.string('tags', minLength: 1).list();
  /// ```
  Field<List<T>> list({List<T>? fallback}) => Field<List<T>>._internal(
    name: name,
    aliases: aliases,
    validator: validator.list(fallback: fallback),
  );

  /// Makes the field a map of values of the original type.
  ///
  /// This transforms a field of type T to a field of type [Map<String, T>], expecting a JSON object where each value is validated against the original field's rules.
  ///
  /// Parameters:
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a new field that validates maps with string keys and values of the original type.
  ///
  /// Example:
  /// ```dart
  /// final metadataField = Field.string('metadata', minLength: 1).map();
  /// ```
  Field<Map<String, T>> map({Map<String, T>? fallback}) => Field<Map<String, T>>._internal(
    name: name,
    aliases: aliases,
    validator: validator.map(fallback: fallback),
  );

  /// Creates a field for nested objects that are validated using a schema.
  ///
  /// This factory method creates a field that applies another schema to a nested JSON object, allowing for complex, hierarchical validation structures.
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [schema]: The schema to apply to the nested object
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a field that validates nested objects according to the provided schema.
  ///
  /// Example:
  /// ```dart
  /// final addressSchema = Schema<Address>(...);
  /// final addressField = Field.nested('address', schema: addressSchema);
  /// ```
  Field.nested(this.name, {this.aliases = const [], required Schema<T> schema, T? fallback})
    : validator = Validator.schema(schema: schema, fallback: fallback);

  /// Creates a field that accepts values of type T without conversion.
  ///
  /// Use this for simple fields where no validation or transformation is needed, and the JSON value is already of the correct type.
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a field that accepts values of type T without additional validation.
  ///
  /// Example:
  /// ```dart
  /// final isActiveField = Field<bool>.plain('isActive', fallback: false);
  /// ```
  Field.plain(this.name, {this.aliases = const [], T? fallback}) : validator = Validator<T>.plain(fallback: fallback);

  /// Creates a field with a custom conversion function.
  ///
  /// This is the most flexible field factory, allowing you to define custom validation and transformation logic for a field.
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [converter]: Function that converts values of type J to type T
  /// - [fallback]: Optional default value to use if the field is missing
  /// - [fallbackBuilder]: Optional function to create a default value if the field is missing
  ///
  /// Returns a field with custom validation logic defined by the converter function.
  ///
  /// Example:
  /// ```dart
  /// final colorField = Field.custom<Color, String>(
  ///   'color',
  ///   converter: (value) => Color.fromHex(value),
  /// );
  /// ```
  static Field<T> custom<T, J>(
    String name, {
    List<String> aliases = const [],
    T Function(J)? converter,
    T? fallback,
    T Function()? fallbackBuilder,
  }) {
    converter ??= (value) => value as T;
    return Field<T>._internal(
      name: name,
      aliases: aliases,
      validator: Validator.custom<T, J>(
        converter: (value, path) => converter!(value),
        fallback: fallback,
        fallbackBuilder: fallbackBuilder,
      ),
    );
  }

  /// Creates a field for integer values with optional range validation.
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [min]: Optional minimum value (inclusive)
  /// - [max]: Optional maximum value (inclusive)
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a field that validates integers and ensures they fall within the specified range.
  ///
  /// Throws a ValidationException if:
  /// - The value is not convertible to an integer
  /// - The value is less than [min] (if specified)
  /// - The value is greater than [max] (if specified)
  ///
  /// Example:
  /// ```dart
  /// final ageField = Field.integer('age', min: 0, max: 120);
  /// ```
  static Field<int> integer(String name, {List<String> aliases = const [], int? min, int? max, int? fallback}) =>
      Field<int>._internal(
        name: name,
        aliases: aliases,
        validator: Validator.integer(min: min, max: max, fallback: fallback),
      );

  /// Creates a field for string values with various validation options.
  ///
  /// This factory method provides numerous options for validating string values, including length constraints, pattern matching, case formatting, and more.
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [minLength]: Optional minimum string length
  /// - [maxLength]: Optional maximum string length
  /// - [pattern]: Optional RegExp pattern the string must match
  /// - [trim]: Whether to trim whitespace before validation
  /// - [coerce]: Whether to coerce non-string values to strings
  /// - [options]: Set of allowed string values
  /// - [caseType]: Optional case transformation to apply (lowercase/uppercase)
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a field that validates strings according to the specified rules.
  ///
  /// Throws a ValidationException if:
  /// - The value is not a string (if coerce is false)
  /// - The string length is less than minLength (if specified)
  /// - The string length is greater than maxLength (if specified)
  /// - The string doesn't match the pattern (if specified)
  /// - The string is not one of the allowed options (if specified)
  ///
  /// Example:
  /// ```dart
  /// final nameField = Field.string('name',
  ///   minLength: 2,
  ///   maxLength: 50,
  ///   trim: true,
  /// );
  /// ```
  static Field<String> string(
    String name, {
    List<String> aliases = const [],
    int? minLength,
    int? maxLength,
    RegExp? pattern,
    bool trim = false,
    bool coerce = false,
    Set<String>? options,
    StringCase? caseType,
    String? fallback,
  }) => Field<String>._internal(
    name: name,
    aliases: aliases,
    validator: Validator.string(
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      trim: trim,
      options: options,
      caseType: caseType,
      coerce: coerce,
      fallback: fallback,
    ),
  );

  /// Creates a field for DateTime values with various parsing and validation options.
  ///
  /// This field can parse dates from ISO8601 strings and timestamps, and validate that they fall within a specified range.
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [min]: Optional minimum date/time (inclusive)
  /// - [max]: Optional maximum date/time (inclusive)
  /// - [fallback]: Optional default value to use if the field is missing
  /// - [allowIso8601]: Whether to allow parsing ISO8601 formatted strings
  /// - [allowTimestamp]: Whether to allow parsing numeric timestamp values
  ///
  /// Returns a field that validates and converts to DateTime instances.
  ///
  /// Throws a ValidationException if:
  /// - The value cannot be parsed as a date/time
  /// - The date/time is earlier than min (if specified)
  /// - The date/time is later than max (if specified)
  ///
  /// Example:
  /// ```dart
  /// final birthdateField = Field.datetime('birthdate',
  ///   min: DateTime(1900),
  ///   max: DateTime.now(),
  /// );
  /// ```
  static Field<DateTime> datetime(
    String name, {
    List<String> aliases = const [],
    DateTime? min,
    DateTime? max,
    DateTime? fallback,
    bool allowIso8601 = true,
    bool allowTimestamp = true,
  }) => Field<DateTime>._internal(
    name: name,
    aliases: aliases,
    validator: Validator.datetime(
      min: min,
      max: max,
      fallback: fallback,
      allowIso8601: allowIso8601,
      allowTimestamp: allowTimestamp,
    ),
  );

  /// Creates a field for enum values mapped from strings.
  ///
  /// This factory method allows mapping string values in JSON to enum values using a provided dictionary.
  ///
  /// Despite its intended use for enums, it can also be used for any type, so long as [values] is a map of strings to objects of type [T].
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [values]: Map of string values to enum values
  /// - [caseSensitive]: Whether string matching is case-sensitive
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a field that converts strings to enum values based on the provided mapping.
  ///
  /// Throws a ValidationException if the input string doesn't match any key in the values map.
  ///
  /// Example:
  /// ```dart
  /// enum Color { red, green, blue }
  ///
  /// final colorField = Field.enumeration<Color>('color',
  ///   values: Color.values.asNameMap(),
  ///   caseSensitive: false,
  /// );
  /// ```
  Field.enumeration(
    this.name, {
    this.aliases = const [],
    required Map<String, T> values,
    bool caseSensitive = false,
    T? fallback,
  }) : validator = Validator.enumeration<T>(values: values, caseSensitive: caseSensitive, fallback: fallback);

  /// Creates a field that converts a string value into a RegExp object.
  ///
  /// This field validates that the input is a string containing a valid regular expression and converts it into a RegExp object with the specified options.
  ///
  /// Parameters:
  /// - [name]: The name of the field in the JSON
  /// - [aliases]: Alternative names for the field
  /// - [full]: Whether to anchor the pattern with ^ and $ if not already present
  /// - [multiLine]: Whether to enable multi-line mode in the RegExp
  /// - [caseSensitive]: Whether the RegExp should be case-sensitive
  /// - [unicode]: Whether to enable Unicode support in the RegExp
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a field that validates string patterns and converts them to RegExp objects.
  ///
  /// Throws a ValidationException if the input string is not a valid regular expression.
  ///
  /// Example:
  /// ```dart
  /// final searchPatternField = Field.pattern('searchPattern',
  ///   full: true,
  ///   caseSensitive: false,
  /// );
  /// ```
  static Field<RegExp> pattern(
    String name, {
    List<String> aliases = const [],
    bool full = false,
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    RegExp? fallback,
  }) => Field<RegExp>._internal(
    name: name,
    aliases: aliases,
    validator: Validator.pattern(
      full: full,
      multiLine: multiLine,
      caseSensitive: caseSensitive,
      unicode: unicode,
      fallback: fallback,
    ),
  );
}
