import "exceptions.dart" show ValidationException;
import "field.dart" show Field;
import "json_path.dart" show JsonPath;
import "option.dart" show Option;

/// Defines a schema for validating and constructing objects from JSON data.
///
/// The schema contains field definitions that specify how each property in the JSON should be validated and transformed before being passed to the constructor. Each schema is generic over the type T it produces when validating JSON input.
///
/// Example:
/// ```dart
/// final personSchema = Schema(
///   fields: [
///     Field.string('name', minLength: 2),
///     Field.integer('age', min: 0),
///   ],
///   constructor: (data) => Person(name: data['name'], age: data['age']),
/// );
///
/// try {
///   final person = personSchema.fromJson(jsonData);
///   // Use the validated person object
/// } on ValidationException catch (e) {
///   print('Validation error: ${e.message} at ${e.path}');
/// }
/// ```
class Schema<T> {
  /// The field definitions that make up this schema.
  ///
  /// Each field defines how a property in the JSON is validated and transformed.
  final List<Field> fields;

  /// Function that constructs an instance of T from validated data.
  ///
  /// This constructor receives a [Map<String, dynamic>] containing the validated field values and should return an instance of type T.
  ///
  /// The constructor will receive a map where each key corresponds to a field name and each value is the validated value for that field and is of the generic type of the field (e.g., [String] for a [Field<String>], [int?] for a [Field<int>], etc.). This is the case even if the field was absent in the JSON input or if it was present with an alias.
  ///
  /// The function may throw an [ArgumentError], [FormatException], or [TypeError] if the data is not suitable for constructing an instance of T. The exception will be caught and rethrown as a [ValidationException] with the appropriate path information.
  final T Function(Map<String, dynamic> data) constructor;

  /// Creates a schema with the specified fields and constructor.
  ///
  /// All fields must be provided when creating the schema, along with a constructor function that will build the final object using validated data.
  const Schema({required this.fields, required this.constructor});

  /// Validates and converts a single JSON object to type T.
  ///
  /// This is the main entry point for validating and converting JSON data.
  ///
  /// Throws [ValidationException] if the input fails validation.
  T fromJson(dynamic json) => validate(json);

  /// Validates and converts a list of JSON objects to a [List<T>].
  ///
  /// Use this method when your JSON input is an array of objects that should each be validated against this schema.
  ///
  /// Throws [ValidationException] if the input is not a list or if any item fails validation. The ValidationException's path will indicate which item in the list failed.
  List<T> list(dynamic json) {
    final list = ValidationException.handle(json, JsonPath.root(), () => (json as Iterable).cast<dynamic>());
    return [for (final (index, item) in list.indexed) validate(item, JsonPath.root()[index])];
  }

  /// Validates and converts a map of JSON objects to a [Map<String, T>].
  ///
  /// Use this method when your JSON input is an object whose properties should each be validated against this schema.
  ///
  /// Throws [ValidationException] if the input is not a map or if any value fails validation. The ValidationException's path will indicate which key in the map failed.
  Map<String, T> map(dynamic json) {
    final map = ValidationException.handle(json, JsonPath.root(), () => (json as Map).cast<String, dynamic>());
    return {for (final entry in map.entries) entry.key: validate(entry.value, JsonPath.root() / entry.key)};
  }

  /// Validates a JSON object against this schema and constructs an instance of T.
  ///
  /// This method performs the actual validation work, checking that:
  /// 1. The input is a valid Map with String keys
  /// 2. All required fields are present
  /// 3. All fields pass their individual validations
  /// 4. The constructor can successfully build an object of type T
  ///
  /// Throws [ValidationException] in the following cases:
  /// - If the input is not a Map or does not have String keys
  /// - If a required field is missing
  /// - If a field fails validation
  /// - If the constructor throws an ArgumentError, FormatException, or TypeError
  T validate(dynamic json, [JsonPath path = const JsonPath.root()]) {
    return ValidationException.handle(json, path, () {
      final jsonMap = (json as Map).cast<String, dynamic>();
      final data = {for (final field in fields) field.name: _value(field, jsonMap, path / field.name)};
      return constructor(data);
    });
  }

  /// Validates a field's value in the JSON using its validator.
  U _value<U>(Field<U> field, Map<String, dynamic> json, JsonPath path) {
    final value = _jsonValue(json, field);
    return ValidationException.handle(value, path, () => field.validator.validateWithPath(value, path));
  }

  /// Attempts to find the field's value in the JSON using the primary name and aliases.
  Option<dynamic> _jsonValue(Map<String, dynamic> json, Field field) {
    final key = <String?>[field.name, ...field.aliases].firstWhere((key) => json.containsKey(key), orElse: () => null);
    return key == null ? const Option.empty() : Option.value(json[key]);
  }
}
