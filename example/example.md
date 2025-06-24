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
  static final schema = Schema(
    fields: [
      Field.string("name"),
      Field.string("species", fallback: "Unknown"),
      Field.integer("age").optional(),
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
)
```

### Integer Fields

```dart
Field.integer(
  "age",
  min: 0,            // Minimum value
  max: 120,          // Maximum value
  fallback: 18,      // Default value if missing
)
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
)
```

### Enum Fields

```dart
enum Color { red, green, blue }

Field.enumeration<Color>(
  "color",
  values: Color.asNameMap(), // Map of enum values
  caseSensitive: false, // Case-insensitive matching
  fallback: Color.blue, // Default value if missing
)
```

### Nested Schema Fields

```dart
// First, define the nested schema
class Address {
  final String street;
  final int? number;
  Address({required this.street, this.number});

  static final schema = Schema(
    fields: [
      Field.string("street"),
      Field.integer("number").optional(),
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
)
```

### List Fields

```dart
// For a list of strings
Field.string("tags").list()

// For a list of nested objects
Field.nested("items", schema: Item.schema).list()
```

## Field Options

All field types support these options:

- **aliases**: Alternative field names to look for in the JSON
- **fallback**: Default value if the field is missing
- **optional()**: Mark a field as optional (can be null)
- **list()**: Indicates that the field can contain multiple values
- **map()**: Indicates that the field is a map of key-value pairs

```dart
Field.string("name", aliases: ["fullName", "userName"])
Field.integer("score").optional() // Can be null
```

## Error Handling

JSON Guard throws descriptive exceptions when validation fails:

```dart
try {
  final character = Character.schema.fromJson(jsonData);
} on ValidationException catch (e) {
  print("$e");
  // e.g., "Validation error at $.age (value: 150, type: int): Value must be at most 120"
}
```

## Using the Validator Class

The `Validator<T>` class is the core validation engine of the JSON Guard library. It handles:

1. Converting raw JSON values to specific Dart types
2. Validating that values meet constraints
3. Handling missing fields with fallbacks
4. Managing optional fields that may be null

A `Validator<T>` is a self-contained object that can:
- Take a raw JSON value as input
- Validate and convert it to a type `T`
- Throw a `ValidationException` if validation fails

### Built-in Validator Types

JSON Guard provides several built-in validator factory methods:

```dart
// Basic validators
final intValidator = Validator.integer(min: 0, max: 100);
final stringValidator = Validator.string(minLength: 3, maxLength: 50);
final dateValidator = Validator.datetime(min: DateTime(2020));
final regexValidator = Validator.pattern(caseSensitive: false);
final enumValidator = Validator.enumeration<Status>(values: {'active': Status.active, 'inactive': Status.inactive});

// For values that don't need conversion
final boolValidator = Validator<bool>.plain();

// For custom validation logic
final urlValidator = Validator.custom<Uri, String>(
  converter: (value, path) => Uri.parse(value),
);
```

### Validator Transformations

Validators can be transformed to handle different shapes of data:

```dart
// Optional validators accept null values
final optionalInt = Validator.integer().optional();  // Validator<int?>

// List validators validate each item in a list
final stringList = Validator.string().list();  // Validator<List<String>>

// Map validators validate each value in a map
final stringMap = Validator.string().map();  // Validator<Map<String, String>>
```

### Using Validators Directly

Validators can be used directly without involving Fields or Schemas:

```dart
final emailValidator = Validator.string(
  pattern: RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$'),
);

try {
  final validatedEmail = emailValidator.validate('user@example.com');
  print('Email is valid: $validatedEmail');
} on ValidationException catch (e) {
  print('Invalid email: ${e.message}');
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
