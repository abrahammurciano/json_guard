import "exceptions.dart" show WrongJsonTypeException;
import "field_builder.dart" show FieldBuilder;
import "schema.dart" show Schema;
import "validators/datetime_validator.dart" show DateTimeValidator;
import "validators/enum_validator.dart" show EnumValidator;
import "validators/integer_validator.dart" show IntegerValidator;
import "validators/pattern_validator.dart" show PatternValidator;
import "validators/string_validator.dart" show StringValidator, StringCase;

/// Factory for creating fields with various validation rules.
///
/// This class provides a set of static methods to create field definitions with
/// type-specific validations. These fields can be used to build a schema for
/// validating JSON objects.
abstract class Field {
  /// Creates a field that accepts values of type T without conversion.
  ///
  /// Use this for simple fields where no validation or transformation is needed.
  static FieldBuilder<T> plain<T>(String name, {List<String> aliases = const [], T? fallback}) {
    return FieldBuilder<T>(name: name, aliases: aliases, fallback: fallback, converter: (value, _, _) => value);
  }

  /// Creates a field with a custom conversion function.
  ///
  /// Use this to define fields with custom validation or transformation logic.
  static FieldBuilder<T> custom<T, J>(
    String name, {
    List<String> aliases = const [],
    T Function(J)? converter,
    T? fallback,
    T Function()? fallbackBuilder,
  }) {
    converter ??= (value) => value as T;
    return FieldBuilder<T>(
      name: name,
      aliases: aliases,
      converter: (value, path, field) {
        if (value is! J) {
          throw WrongJsonTypeException(value, expected: J.toString(), field: field, path: path);
        }
        return converter!(value);
      },
      fallback: fallback,
      fallbackBuilder: fallbackBuilder,
    );
  }

  /// Creates a field for integer values with optional range validation.
  ///
  /// The field will validate that the value is an integer and optionally that it falls
  /// within the specified range.
  static FieldBuilder<int> integer(String name, {List<String> aliases = const [], int? min, int? max, int? fallback}) {
    return FieldBuilder<int>(
      name: name,
      aliases: aliases,
      converter: IntegerValidator(min: min, max: max).validate,
      fallback: fallback,
    );
  }

  /// Creates a field for string values with various validation options.
  ///
  /// The field can validate string length, pattern matching, case formatting,
  /// and more.
  static FieldBuilder<String> string(
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
  }) {
    return FieldBuilder<String>(
      name: name,
      aliases: aliases,
      converter: StringValidator(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        trim: trim,
        options: options,
        caseType: caseType,
        coerce: coerce,
      ).validate,
      fallback: fallback,
    );
  }

  /// Creates a field for DateTime values with validation options.
  ///
  /// The field can parse dates from ISO8601 strings and timestamps,
  /// and validate that they fall within a specified range.
  static FieldBuilder<DateTime> datetime(
    String name, {
    List<String> aliases = const [],
    DateTime? min,
    DateTime? max,
    DateTime? fallback,
    bool allowIso8601 = true,
    bool allowTimestamp = true,
  }) {
    return FieldBuilder<DateTime>(
      name: name,
      aliases: aliases,
      converter: DateTimeValidator(
        min: min,
        max: max,
        allowIso8601: allowIso8601,
        allowTimestamp: allowTimestamp,
      ).validate,
      fallback: fallback,
    );
  }

  /// Creates a field for enum values mapped from strings.
  ///
  /// The field maps string values from JSON to enum values using the provided map.
  static FieldBuilder<E> enumeration<E>(
    String name, {
    List<String> aliases = const [],
    required Map<String, E> values,
    bool caseSensitive = false,
    E? fallback,
  }) {
    return FieldBuilder<E>(
      name: name,
      aliases: aliases,
      converter: EnumValidator<E>(values: values, caseSensitive: caseSensitive).validate,
      fallback: fallback,
    );
  }

  /// Creates a field for nested objects that are validated using a schema.
  ///
  /// The field applies a schema to a nested JSON object to validate and transform it.
  static FieldBuilder<T> nested<T>(
    String name, {
    List<String> aliases = const [],
    required Schema<T> schema,
    T? fallback,
  }) {
    return FieldBuilder<T>(name: name, aliases: aliases, converter: schema.validate, fallback: fallback);
  }

  /// Creates a field for string values that must match a regular expression pattern.
  ///
  /// The field will validate that the value is a string and that it matches the specified pattern.
  /// Creates a field that converts a string value into a RegExp object.
  ///
  /// If [full] is true, the pattern will be anchored with ^ and $ if they are not already present.
  /// The [multiLine], [caseSensitive], and [unicode] parameters control the RegExp options.
  static FieldBuilder<RegExp> pattern(
    String name, {
    List<String> aliases = const [],
    bool full = false,
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    RegExp? fallback,
  }) {
    return FieldBuilder<RegExp>(
      name: name,
      aliases: aliases,
      converter: PatternValidator(
        full: full,
        multiLine: multiLine,
        caseSensitive: caseSensitive,
        unicode: unicode,
      ).validate,
      fallback: fallback,
    );
  }
}
