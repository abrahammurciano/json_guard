# JSON Guard Examples

`json_guard` is a Dart library for robust JSON validation and transformation. It helps you convert JSON objects into strongly-typed Dart objects with full validation of fields and constraints.

## Basic Usage

To use `json_guard`, you need to:

1. Define your data model class
2. Create a `Schema` with field definitions
3. Use the schema to validate and transform JSON

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

// 1. Define your data model
class Character {
  final String name;
  final String species;
  final int? age;

  Character({required this.name, required this.species, this.age});

  // 2. Define the schema
  static final schema = Schema<Character>(
    fields: [
      Field.string("name").field(),
      Field.string("species", fallback: "Unknown").field(),
      Field.integer("age").optional().field(),
    ],
    constructor: (data) => Character(
      name: data["name"],
      species: data["species"],
      age: data["age"],
    ),
  );
}

// 3. Use the schema to validate and transform
final lukeJson = {"name": "Luke Skywalker", "species": "Human", "age": 23};
final yodaJson = {"name": "Yoda"};

final luke = Character.schema.fromJson(lukeJson);
final yoda = Character.schema.fromJson(yodaJson);
```

## Field Types

JSON Guard supports various field types, each with its own validation rules:

### String Fields

```dart
Field.string(
  "name",
  minLength: 3,       // Minimum length constraint
  maxLength: 50,      // Maximum length constraint
  pattern: RegExp(r'^[A-Z]'), // Regular expression pattern
  trim: true,         // Trim whitespace
  options: {"a", "b"}, // Allowed values
  fallback: "default", // Default value if missing
).field()
```

### Integer Fields

```dart
Field.integer(
  "age",
  min: 0,            // Minimum value
  max: 120,          // Maximum value
  fallback: 18,      // Default value if missing
).field()
```

### DateTime Fields

```dart
Field.datetime(
  "birthDate",
  min: DateTime(1900), // Minimum date
  max: DateTime.now(), // Maximum date
  allowIso8601: true,  // Accept ISO8601 string format
  allowTimestamp: true, // Accept UNIX timestamp (seconds)
  fallback: DateTime(2000), // Default value if missing
).field()
```

### Enum Fields

```dart
enum Color { red, green, blue }

Field.enumeration<Color>(
  "color",
  values: Color.asNameMap(), // Map of enum values
  caseSensitive: false, // Case-insensitive matching
  fallback: Color.blue, // Default value if missing
).field()
```

### Nested Schema Fields

```dart
// First, define the nested schema
class Address {
  final String street;
  final int? number;
  Address({required this.street, this.number});

  static final schema = Schema<Address>(
    fields: [
      Field.string("street").field(),
      Field.integer("number").optional().field(),
    ],
    constructor: (data) => Address(
      street: data["street"],
      number: data["number"],
    ),
  );
}

// Then use it in the parent schema
Field.nested(
  "address",
  schema: Address.schema, // The nested schema
  fallback: defaultAddress, // Optional default value
).field()
```

### List Fields

```dart
// For a list of strings
Field.string("tags").list().field()

// For a list of nested objects
Field.nested("items", schema: Item.schema).list().field()
```

## Field Options

All field types support these options:

- **aliases**: Alternative field names to look for in the JSON
- **fallback**: Default value if the field is missing
- **optional()**: Mark a field as optional (can be null)
- **list()**: Indicates that the field can contain multiple values
- **map()**: Indicates that the field is a map of key-value pairs

```dart
Field.string("name", aliases: ["fullName", "userName"]).field()
Field.integer("score").optional().field() // Can be null
```

## Error Handling

JSON Guard throws descriptive exceptions when validation fails:

```dart
try {
  final character = Character.schema.fromJson(jsonData);
} catch (e) {
  print("$e");
  // e.g., "Field 'age': Validation failed for value '150': Value must be at most 120 (at $.age)"
}
```

## Complete Examples

For complete examples of using JSON Guard, see the example directory:

- [Basic validation](example/basic_example.dart)
- [String field features](example/string_validation_example.dart)
- [DateTime field validation](example/datetime_validation_example.dart)
- [Enum field validation](example/enum_validation_example.dart)
- [Nested schema validation](example/nested_schema_example.dart)
- [List field validation](example/list_validation_example.dart)
- [Custom validation](example/custom_validation_example.dart)
