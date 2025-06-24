import "json_path.dart" show JsonPath;
import "option.dart" show Option;

/// Exception thrown when JSON data fails validation.
///
/// This is the only exception type thrown by JsonGuard, consolidating all validation errors into a single, unified exception type. It provides detailed information about what went wrong during validation, including:
/// - The path to the field that failed validation
/// - The value that caused the validation error (if available)
/// - A descriptive message explaining why validation failed
///
/// This class also handles converting other error types (like ArgumentError, FormatException, and TypeError) into ValidationExceptions to provide a consistent error handling experience.
class ValidationException implements Exception {
  /// The value that caused the validation error, if any.
  ///
  /// This is wrapped in an Option to handle cases where there is no value (e.g., missing required field).
  final Option<Object?> value;

  /// A descriptive message about what went wrong during validation.
  ///
  /// This provides detailed information about why validation failed, such as constraint violations, type mismatches, or missing required fields.
  ///
  /// For the full error message, it is recommended to use the [toString] method, which includes the value and path information.
  final String message;

  /// The path to the property in the JSON that caused the validation error.
  ///
  /// Uses JSONPath syntax (e.g., `$.user.address[0].zipCode`) to identify exactly where in the JSON structure the error occurred.
  final JsonPath path;

  /// Creates a validation exception with the specified value, message, and path.
  const ValidationException._(this.value, this.message, this.path);

  /// Creates a validation exception for a missing required field.
  ///
  /// The [path] parameter identifies which field was missing.
  const ValidationException.missing(this.path) : value = const Option.empty(), message = "Missing required field";

  @override
  String toString() => "Validation error at $path ($_valueInfo): $message";

  /// Formats the value information for inclusion in error messages.
  String get _valueInfo => value.when(value: (v) => "value: $v, type: ${v.runtimeType}", empty: () => "no value");

  /// Executes a function and converts any ArgumentError, FormatException, or TypeError to a ValidationException.
  ///
  /// This utility method allows code to gracefully handle errors that might occur during validation or conversion, ensuring they're presented as ValidationExceptions with proper context about where and why they occurred.
  ///
  /// Parameters:
  /// - [value]: The value being validated or converted
  /// - [path]: The JSON path where the operation is occurring
  /// - [function]: The function to execute that might throw errors
  ///
  /// Returns the result of [function] if it completes successfully.
  ///
  /// Throws a ValidationException if [function] throws an ArgumentError, FormatException, or TypeError.
  static T handle<T>(Object? value, JsonPath path, T Function() function) {
    try {
      return function();
    } on ArgumentError catch (e) {
      throw ValidationException._(Option.value(value), e.message.toString(), path);
    } on TypeError catch (e) {
      throw ValidationException._(Option.value(value), e.toString(), path);
    } on FormatException catch (e) {
      throw ValidationException._(Option.value(value), e.message, path);
    }
  }
}
