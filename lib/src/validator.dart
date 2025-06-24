import "exceptions.dart" show ValidationException;
import "field.dart" show Converter;
import "json_path.dart" show JsonPath;
import "option.dart" show Option;
import "schema.dart" show Schema;
import "validators/datetime_validator.dart" show DateTimeValidator;
import "validators/enum_validator.dart" show EnumValidator;
import "validators/integer_validator.dart" show IntegerValidator;
import "validators/pattern_validator.dart" show PatternValidator;
import "validators/string_validator.dart" show StringValidator, StringCase;

/// Validates and converts JSON values according to specified rules.
///
/// The Validator class is responsible for:
/// - Converting raw JSON values to specific Dart types
/// - Validating that values meet constraints
/// - Handling missing fields with fallbacks or errors
/// - Managing optional fields that may be null
///
/// Validators are typically created by the Field factory methods and used internally by the Schema class during validation.
class Validator<T> {
  /// Optional fallback value to use if the field is missing.
  ///
  /// If provided, this value will be used when the field is absent from the JSON.
  final T? fallback;

  /// Optional function to build a fallback value if the field is missing.
  ///
  /// This is useful for dynamic fallbacks or when the fallback needs to be created fresh each time (like a new List or DateTime.now()).
  final T Function()? fallbackBuilder;

  /// Function to convert the JSON value to the target type.
  ///
  /// This function performs the actual validation and transformation of the value. It may throw a ValidationException if the value cannot be converted or validated.
  final Converter<T> converter;

  /// Whether the field is optional (can be null).
  ///
  /// If true, null values are accepted. Otherwise, null values will cause validation errors.
  final bool allowsNull;

  /// Whether the field is required (must be present in the JSON).
  ///
  /// A field is required if it is not optional and has no fallback value or builder.
  bool get _isRequired => !allowsNull && fallback == null && fallbackBuilder == null;

  /// Creates a validator with the specified properties.
  ///
  /// Parameters:
  /// - [fallback]: Optional default value to use if the field is missing
  /// - [fallbackBuilder]: Optional function to create a default value if the field is missing
  /// - [converter]: Function to convert and validate the JSON value
  /// - [allowsNull]: Whether the field is optional (can be null)
  ///
  /// You cannot provide both a fallback value and a fallback builder.
  const Validator._({required this.fallback, this.fallbackBuilder, required this.converter, this.allowsNull = false})
    : assert(fallbackBuilder == null || fallback == null, "Cannot provide both fallback and fallbackBuilder.");

  /// Validates and converts a JSON value.
  ///
  /// You can use this method to validate single values without a whole schema.
  ///
  /// Parameters:
  /// - [value]: The value to validate, which can be null or any object
  ///
  /// Returns the validated and converted value of type T.
  ///
  /// Throws a ValidationException if:
  /// - The value is missing and the field is required
  /// - The value cannot be converted to the target type
  /// - The value fails validation constraints
  T validate(Object? value) {
    return validateWithPath(allowsNull ? Option.value(value) : Option.maybe(value), JsonPath.root());
  }

  /// Makes the validator optional, allowing null values.
  ///
  /// By default, validators require non-null values and will cause validation errors if they receive null. Calling this method makes the validator accept null values.
  ///
  /// Returns a new validator of type T? that accepts null values.
  ///
  /// Example:
  /// ```dart
  /// final optionalAge = Validator.integer('age', min: 0).optional();
  /// ```
  Validator<T?> optional() {
    return Validator<T?>._(
      fallback: fallback,
      fallbackBuilder: fallbackBuilder,
      converter: (value, path) => value == null ? null : converter(value, path),
      allowsNull: true,
    );
  }

  /// Converts the validator to validate lists of the original type.
  ///
  /// This transforms a validator of type T to a validator of type [List<T>], validating each element in a list using the original validator's rules.
  ///
  /// Parameters:
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a new validator that validates lists of the original type.
  ///
  /// Example:
  /// ```dart
  /// final tagsValidator = Validator.string(minLength: 2).list();
  /// ```
  Validator<List<T>> list({List<T>? fallback}) {
    return Validator<List<T>>._(
      converter: (value, path) {
        return [for (final (index, item) in (value as Iterable).indexed) converter(item, path[index])];
      },
      fallback: fallback,
      allowsNull: allowsNull,
    );
  }

  /// Converts the validator to validate maps with values of the original type.
  ///
  /// This transforms a validator of type T to a validator of type [Map<String, T>], validating each value in a map using the original validator's rules.
  ///
  /// Parameters:
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a new validator that validates maps with string keys and values of the original type.
  ///
  /// Example:
  /// ```dart
  /// final metadataValidator = Validator.string().map();
  /// ```
  Validator<Map<String, T>> map({Map<String, T>? fallback}) {
    return Validator<Map<String, T>>._(
      converter: (value, path) {
        return {
          for (final entry in Map<String, dynamic>.from(value).entries)
            entry.key: converter(entry.value, path / entry.key),
        };
      },
      fallback: fallback,
      allowsNull: allowsNull,
    );
  }

  /// Creates a validator that accepts values of type T without conversion.
  ///
  /// Parameters:
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a validator that accepts values of type T without additional validation.
  ///
  /// Example:
  /// ```dart
  /// final isActiveValidator = Validator.plain(fallback: false);
  /// ```
  Validator.plain({this.fallback}) : converter = ((value, _) => value as T), allowsNull = false, fallbackBuilder = null;

  /// Creates a validator with a custom conversion function.
  ///
  /// This is the most flexible validator factory, allowing you to define custom validation and transformation logic.
  ///
  /// Parameters:
  /// - [converter]: Function that converts values of type J to type T
  /// - [fallback]: Optional default value to use if the field is missing
  /// - [fallbackBuilder]: Optional function to create a default value if the field is missing
  ///
  /// Returns a validator with custom validation logic defined by the converter function.
  ///
  /// Example:
  /// ```dart
  /// final colorValidator = Validator.custom<Color, String>(
  ///   converter: (value) => Color.fromHex(value),
  /// );
  /// ```
  static Validator<T> custom<T, J>({
    required T Function(J, JsonPath) converter,
    T? fallback,
    T Function()? fallbackBuilder,
  }) => Validator<T>._(
    converter: (value, path) => converter(value as J, path),
    fallback: fallback,
    fallbackBuilder: fallbackBuilder,
  );

  /// Creates an integer validator with optional range validation.
  ///
  /// Parameters:
  /// - [min]: Optional minimum value (inclusive)
  /// - [max]: Optional maximum value (inclusive)
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a validator that validates integers and ensures they fall within the specified range.
  ///
  /// Example:
  /// ```dart
  /// final ageValidator = Validator.integer(min: 0, max: 120);
  /// ```
  static Validator<int> integer({int? min, int? max, int? fallback}) {
    final validator = IntegerValidator(min: min, max: max);
    return Validator<int>._(converter: (value, _) => validator.validate(value), fallback: fallback);
  }

  /// Creates a string validator with various validation options.
  ///
  /// Parameters:
  /// - [minLength]: Optional minimum string length
  /// - [maxLength]: Optional maximum string length
  /// - [pattern]: Optional RegExp pattern the string must match
  /// - [trim]: Whether to trim whitespace before validation
  /// - [coerce]: Whether to coerce non-string values to strings
  /// - [options]: Set of allowed string values
  /// - [caseType]: Optional case transformation to apply (lowercase/uppercase)
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a validator that validates strings according to the specified rules.
  ///
  /// Example:
  /// ```dart
  /// final nameValidator = Validator.string(
  ///   minLength: 2,
  ///   maxLength: 50,
  ///   trim: true,
  /// );
  /// ```
  static Validator<String> string({
    int? minLength,
    int? maxLength,
    RegExp? pattern,
    bool trim = false,
    bool coerce = false,
    Set<String>? options,
    StringCase? caseType,
    String? fallback,
  }) {
    final validator = StringValidator(
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      trim: trim,
      options: options,
      caseType: caseType,
      coerce: coerce,
    );
    return Validator<String>._(converter: (value, _) => validator.validate(value), fallback: fallback);
  }

  /// Creates a datetime validator with various parsing and validation options.
  ///
  /// Parameters:
  /// - [min]: Optional minimum date/time (inclusive)
  /// - [max]: Optional maximum date/time (inclusive)
  /// - [fallback]: Optional default value to use if the field is missing
  /// - [allowIso8601]: Whether to allow parsing ISO8601 formatted strings
  /// - [allowTimestamp]: Whether to allow parsing numeric timestamp values
  ///
  /// Returns a validator that validates and converts to DateTime instances.
  ///
  /// Example:
  /// ```dart
  /// final birthdateValidator = Validator.datetime(
  ///   min: DateTime(1900),
  ///   max: DateTime.now(),
  /// );
  /// ```
  static Validator<DateTime> datetime({
    DateTime? min,
    DateTime? max,
    DateTime? fallback,
    bool allowIso8601 = true,
    bool allowTimestamp = true,
  }) {
    final validator = DateTimeValidator(min: min, max: max, allowIso8601: allowIso8601, allowTimestamp: allowTimestamp);
    return Validator<DateTime>._(converter: (value, _) => validator.validate(value), fallback: fallback);
  }

  /// Creates a validator for enum values mapped from strings.
  ///
  /// Despite its intended use for enums, it can also be used for any type, so long as [values] is a map of strings to objects of type T.
  ///
  /// Parameters:
  /// - [values]: Map of string values to enum values
  /// - [caseSensitive]: Whether string matching is case-sensitive
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a validator that converts strings to enum values based on the provided mapping.
  ///
  /// Example:
  /// ```dart
  /// enum Color { red, green, blue }
  ///
  /// final colorValidator = Validator.enumeration<Color>(
  ///   values: Color.values.asNameMap(),
  ///   caseSensitive: false,
  /// );
  /// ```
  static Validator<T> enumeration<T>({required Map<String, T> values, bool caseSensitive = false, T? fallback}) {
    final validator = EnumValidator<T>(values: values, caseSensitive: caseSensitive);
    return Validator<T>._(converter: (value, _) => validator.validate(value), fallback: fallback);
  }

  /// Creates a validator that converts a string value into a RegExp object.
  ///
  /// Parameters:
  /// - [full]: Whether to anchor the pattern with ^ and $ if not already present
  /// - [multiLine]: Whether to enable multi-line mode in the RegExp
  /// - [caseSensitive]: Whether the RegExp should be case-sensitive
  /// - [unicode]: Whether to enable Unicode support in the RegExp
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a validator that validates string patterns and converts them to RegExp objects.
  ///
  /// Example:
  /// ```dart
  /// final searchPatternValidator = Validator.pattern(
  ///   full: true,
  ///   caseSensitive: false,
  /// );
  /// ```
  static Validator<RegExp> pattern({
    bool full = false,
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    RegExp? fallback,
  }) {
    final validator = PatternValidator(
      full: full,
      multiLine: multiLine,
      caseSensitive: caseSensitive,
      unicode: unicode,
    );
    return Validator<RegExp>._(converter: (value, _) => validator.validate(value), fallback: fallback);
  }

  /// Creates a validator that applies a schema to a JSON object.
  ///
  /// Parameters:
  /// - [schema]: The schema to apply for validation and conversion of the object
  /// - [fallback]: Optional default value to use if the field is missing
  ///
  /// Returns a validator that validates objects according to the provided schema.
  ///
  /// Example:
  /// ```dart
  /// final addressSchema = Schema<Address>(...);
  /// final addressValidator = Validator.schema(schema: addressSchema);
  /// ```
  Validator.schema({required Schema<T> schema, T? fallback})
    : this._(converter: (value, path) => schema.validate(value, path), fallback: fallback);

  /// Validates and converts a JSON value.
  ///
  /// This method is called by the Schema during validation to process each field.
  ///
  /// Parameters:
  /// - [value]: The value to validate, wrapped in an Option
  /// - [path]: The JSON path to the value being validated
  ///
  /// Returns the validated and converted value of type T.
  ///
  /// Throws a ValidationException if:
  /// - The value is missing and the field is required
  /// - The value cannot be converted to the target type
  /// - The value fails validation constraints
  T validateWithPath(Option<Object?> value, JsonPath path) {
    return value.when(
      empty: () => _isRequired ? (throw ValidationException.missing(path)) : _missing(),
      value: (value) => ValidationException.handle(value, path, () => converter(value, path)),
    );
  }

  /// Returns the fallback value as an Option.
  ///
  /// For optional fields, this always returns a non-empty Option. For required fields, this returns an Option that may be empty.
  Option<T> get _fallback => allowsNull ? Option.value(fallback as T) : Option.maybe(fallback);

  /// Handles the case where a field is missing from the JSON.
  ///
  /// Returns a fallback value if available, otherwise throws an error.
  T _missing() {
    return _fallback.or(
      () => fallbackBuilder != null ? fallbackBuilder!() : throw StateError("Field is required but missing."),
    );
  }
}
