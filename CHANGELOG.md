# Changelog

## 4.0.0

### Error Handling
- Consolidated all error types into a single `ValidationException` class
- Improved error messages with consistent format that includes path, value, type, and message

### Standalone Validator API
- Exposed `Validator` class for direct use without requiring Field or Schema
- Added methods to create and use validators for individual values
- Added support for chaining validators with `optional()`, `list()`, and `map()` methods

### API Improvements
- Enhanced type safety throughout the validation pipeline
- Improved error context and path tracking for nested validations
- Removed the need to finalize fields with `.field()` when creating a schema

## 3.0.0

- Refactored conversion logic to improve type casting errors
- Introduced new exception types for when conversion fails due to type mismatches

## 2.0.0

### RegExp fields
- Added pattern fields with the `Field.pattern()` method to convert JSON strings to RegExp objects
- Added support for anchored patterns with the `full` flag to automatically add ^ and $ if not present

### Map fields
- Added support for map fields with the `map()` method on `FieldBuilder`
- Added `Field.map()` factory method for creating map fields
- Added `map()` method to `Schema` class for processing maps of JSON objects
- Renamed `many()` to `list()` for consistency with `map()` field types

### Proper casting
- Improved type casting for all field types to allow for more flexible JSON parsing

## 1.0.0

- Initial version.
