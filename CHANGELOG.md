# Changelog

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
