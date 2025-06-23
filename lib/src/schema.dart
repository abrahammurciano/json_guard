import "exceptions.dart" show JsonTypeException, ArgumentErrorValidationException, WrongJsonTypeException;
import "field_info.dart" show FieldInfo;
import "json_path.dart" show JsonPath;

/// Defines a schema for validating and constructing objects from JSON data.
///
/// The schema contains field definitions that specify how each property in the JSON
/// should be validated and transformed before being passed to the constructor.
class Schema<T> {
  /// The field definitions that make up this schema.
  final List<FieldInfo> fields;

  /// Function that constructs an instance of T from validated data.
  final T Function(Map<String, dynamic> data) constructor;

  /// Creates a schema with the specified fields and constructor.
  const Schema({required this.fields, required this.constructor});

  /// Validates and converts a single JSON object to type T.
  T fromJson(dynamic json) => validate(json);

  /// Validates and converts a list of JSON objects to a list of type T.
  ///
  /// Throws a [JsonTypeException] if the input is not a list.
  List<T> list(dynamic json) {
    if (json is! Iterable || json is String) {
      throw WrongJsonTypeException(json, expected: "Iterable (other than String)", path: JsonPath.root());
    }
    return [for (final (index, item) in json.indexed) validate(item, JsonPath.root()[index])];
  }

  /// Validates and converts a map of JSON objects to a map of type T.
  ///
  /// Throws a [JsonTypeException] if the input is not a map.
  Map<String, T> map(dynamic json) {
    if (json is! Map) {
      throw WrongJsonTypeException(json, expected: "Map", path: JsonPath.root());
    }
    late final Map<String, dynamic> jsonMap;
    try {
      jsonMap = json.cast<String, dynamic>();
    } catch (e) {
      throw WrongJsonTypeException(jsonMap, expected: "Map<String, dynamic>", path: JsonPath.root());
    }
    return {for (final entry in jsonMap.entries) entry.key: validate(entry.value, JsonPath.root() / entry.key)};
  }

  /// Validates a JSON object against this schema and constructs an instance of T.
  ///
  /// Throws [WrongJsonTypeException] if the input is not a [Map<String, dynamic>].
  /// Throws [ArgumentErrorValidationException] if the constructor raises an ArgumentError.
  T validate(dynamic json, [JsonPath path = const JsonPath.root(), FieldInfo? field]) {
    if (json is! Map) {
      throw WrongJsonTypeException(json, expected: "Map", path: path);
    }
    late final Map<String, dynamic> jsonMap;
    try {
      jsonMap = json.cast<String, dynamic>();
    } catch (e) {
      throw WrongJsonTypeException(jsonMap, expected: "Map<String, dynamic>", path: path);
    }
    final data = {for (final field in fields) field.name: field.value(jsonMap, path / field.name)};

    try {
      return constructor(data);
    } on ArgumentError catch (e) {
      throw ArgumentErrorValidationException(jsonMap, e.message.toString(), field: field, path: path);
    }
  }
}
