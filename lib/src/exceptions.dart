import "field_info.dart" show FieldInfo;
import "json_path.dart" show JsonPath;

/// Base exception class for all exceptions thrown by the JsonGuard library.
class JsonGuardException implements Exception {
  /// Creates a base JsonGuard exception.
  const JsonGuardException();
}

/// Base class for all validation exceptions in the JsonGuard library.
abstract class ValidationException extends JsonGuardException {
  /// The field that failed validation, if applicable.
  final FieldInfo? field;

  /// The path to the property in the JSON that caused the validation error.
  final JsonPath path;

  /// Creates a validation exception with the specified field and path.
  const ValidationException({this.field, required this.path});

  /// The error message describing the validation failure.
  String get message;

  @override
  String toString() => "${field == null ? '' : '$_fieldDescription: '}$message (at $path)";

  /// Returns a description of the field that failed validation.
  String get _fieldDescription =>
      "Field '${field!.name}'${field!.aliases.isEmpty ? '' : ' (aliases: ${field!.aliases.join(', ')})'}";
}

/// Exception thrown when JSON data is not of the expected type.
class JsonTypeException extends ValidationException {
  /// The expected type description.
  final String expected;

  /// The actual data that was provided.
  final dynamic data;

  /// Creates a type exception with the specified data and expected type.
  const JsonTypeException(this.data, {required this.expected, super.field, required super.path});

  @override
  String get message => "Expected JSON with type '$expected' but got '${data.runtimeType}' with value: $data";
}

/// Exception thrown when a required field is missing from the JSON.
class FieldMissingException extends ValidationException {
  /// The JSON data that was being processed.
  final Map<String, dynamic> data;

  /// Creates a missing field exception for the given JSON data.
  FieldMissingException(this.data, {required super.field, required super.path});

  @override
  String get message => "Field missing in JSON. Available keys: ${data.keys.join(', ')}";
}

/// Exception thrown when a value fails validation.
class ValueValidationException extends ValidationException {
  /// The value that failed validation.
  final dynamic value;

  /// The reason why validation failed.
  final String reason;

  /// Creates a value validation exception with the specified value and reason.
  ValueValidationException(this.value, this.reason, {required super.field, required super.path});

  @override
  String get message => "Validation failed for value '$value': $reason";
}

/// Exception thrown when an ArgumentError is raised during object construction.
class ArgumentErrorValidationException extends ValidationException {
  /// The value that caused the ArgumentError.
  final dynamic value;

  /// The reason for the ArgumentError.
  final String reason;

  /// Creates an ArgumentError validation exception with the specified value and reason.
  ArgumentErrorValidationException(this.value, this.reason, {required super.field, required super.path});

  @override
  String get message => "ArgumentError raised for value '$value': $reason";
}
