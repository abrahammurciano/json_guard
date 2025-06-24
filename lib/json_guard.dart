/// JSON Guard is a library for validating and transforming JSON data in Dart.
///
/// It provides a schema-based approach to define how JSON data should be validated,
/// transformed, and constructed into Dart objects. This allows for robust JSON parsing
/// without requiring code generation or complex annotations.
///
/// Key features include:
///
/// - Type validation and conversion with strong typing
/// - No code generation or reflection required
/// - Required and optional field validation
/// - Value constraints (min/max, regex patterns, allowed values)
/// - Detailed error reporting with JSON paths for easy debugging
/// - Support for nested objects, lists, and maps
/// - Custom field conversions and validations
/// - Fallback values for missing fields
///
/// Core components:
/// - [Schema] - Defines the structure and validation rules for a JSON object
/// - [Field] - Defines individual properties within a schema
/// - [ValidationException] - Provides detailed information about validation failures
library;

export "src/exceptions.dart";
export "src/field.dart";
export "src/json_path.dart";
export "src/schema.dart";
export "src/validator.dart";
export "src/validators/string_validator.dart" show StringCase;
