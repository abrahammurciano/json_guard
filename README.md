# JSON Guard

JSON Guard is a lightweight library for validating, transforming, and parsing JSON data in Dart. It provides a type-safe approach to working with JSON without requiring code generation or reflection.

## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Core Concepts](#core-concepts)
  - [Schemas](#schemas)
  - [Fields](#fields)
  - [Validators](#validators)
  - [Type Safety](#type-safety)
  - [Error Handling](#error-handling)
- [Field Types](#field-types)
  - [String](#string-fields)
  - [Integer](#integer-fields)
  - [DateTime](#datetime-fields)
  - [Enum](#enum-fields)
  - [RegExp Pattern](#regex-pattern-fields)
  - [Nested Schema](#nested-schema-fields)
  - [Custom](#custom-fields)
- [Field Modifiers](#field-modifiers)
  - [Optional Fields](#optional-fields)
  - [Lists](#list-fields)
  - [Maps](#map-fields)
  - [Fallback Values](#fallback-values)
  - [Field Aliases](#field-aliases)
- [Advanced Usage](#advanced-usage)
  - [Schema Composition](#schema-composition)
  - [Handling Collections](#handling-collections)
  - [Validating Nested Structures](#validating-nested-structures)
- [Complete Examples](#complete-examples)
  - [Basic Example](#basic-example)
  - [Nested Objects](#nested-objects)
  - [Enum Handling](#enum-handling)
  - [List Validation](#list-validation)
  - [Map Validation](#map-validation)
  - [RegExp Patterns](#regex-patterns)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling-1)
- [Additional Resources](#additional-resources)

## Introduction

JSON Guard provides tools for safely converting JSON data into Dart objects with robust validation and error reporting. Key features include:

- **Type-safe parsing** - Convert JSON to your domain objects with robust type checking
- **Validation** - Ensure values meet your constraints before constructing objects
- **Detailed error reporting** - Get precise error messages with JSON paths to quickly identify issues
- **Zero reflection, zero code-gen** - No reflection or code generation required
- **Composable schemas** - Build complex schemas from simpler building blocks

## Installation

Add JSON Guard to your `pubspec.yaml`:

```yaml
dependencies:
  json_guard: ^1.0.0
```

Then run:

```
dart pub get
```

Import the package in your Dart code:

```dart
import 'package:json_guard/json_guard.dart';
```

## Core Concepts

### Schemas

A `Schema` defines how to validate and transform a JSON object into a strongly typed Dart object. It consists of:

1. **Field definitions** - Describe the fields, types, and validations for the JSON data.
2. **Constructor function** - Specifies how to create your Dart object from the validated data. The constructor receives a map of validated data where each key corresponds to a field defined in the schema. The key names will always be present and match the field names defined in the schema, even if they're absent or use an alias in the JSON input.

```dart
static final schema = Schema(
  fields: [
    Field.string('name', minLength: 2),
    Field.integer('age', min: 0),
  ],
  constructor: (data) => User(
    name: data['name'],
    age: data['age'],
  ),
);
```

### Fields

Fields define how individual JSON properties are validated, transformed, and mapped to your Dart object's properties. JSON Guard provides different field types with type-specific validations.

Each field is created using the `Field` factory class and must be finalized with the `` method:

```dart
Field.string('username', minLength: 3)
```

### Validators

Validators are the core components that handle validation and transformation of values. While they're typically used internally by Fields and Schemas, you can also use them directly for standalone value validation:

```dart
// Create a validator for integers with constraints
final ageValidator = Validator.integer(min: 18, max: 120);

// Validate a value directly
try {
  final age = ageValidator.validate(25); // Returns the validated integer
  print("Valid age: $age");
} on ValidationException catch (e) {
  print("Validation failed: $e");
  // Validation error at $ (value: 25, type: int): Value must be at least 18
}
```

Validators can be combined and modified with methods like:
- `.optional()` - Makes the validator accept null values
- `.list()` - Validates a list of values using the validator's rules
- `.map()` - Validates a map with string keys and values using the validator's rules

You can also provide fallback values for when the input is null or missing:

```dart
final nameValidator = Validator.string(minLength: 2, maxLength: 50, fallback: 'Anonymous');
final tagsValidator = Validator.string().list(fallback: const []);
final metadataValidator = Validator.string().map(fallback: {'version': '1.0'});
```

### Type Safety

JSON Guard ensures type safety by:
- Validating the JSON input against expected types
- Converting values to the appropriate Dart types
- Checking constraints (min/max values, patterns, etc.)
- Providing clear error messages when validation fails

### Error Handling

When validation fails, JSON Guard throws a `ValidationException` with detailed error messages that include:
- The JSON path to the value that failed validation
- The value that caused the validation error and its type
- A descriptive message explaining what went wrong

## Field Types

### String Fields

Validates and transforms string values with options for length constraints, pattern matching, and more.

```dart
Field.string(
  'name',
  minLength: 2,            // Minimum length constraint
  maxLength: 50,           // Maximum length constraint
  pattern: RegExp(r'^[A-Z]'), // Regular expression pattern
  trim: true,              // Trim whitespace
  options: {'admin', 'user', 'guest'}, // Allowed values
  caseType: StringCase.lower, // Convert to lowercase
  coerce: true,            // Convert non-string values to strings
  fallback: 'Anonymous',   // Default value if missing
)
```

### Integer Fields

Validates and converts numeric values to integers with optional range constraints.

```dart
Field.integer(
  'age',
  min: 0,           // Minimum value (inclusive)
  max: 120,         // Maximum value (inclusive)
  fallback: 18,     // Default value if missing
)
```

### DateTime Fields

Parses and validates date-time values from strings or timestamps.

```dart
Field.datetime(
  'birthDate',
  min: DateTime(1900),   // Minimum date (inclusive)
  max: DateTime.now(),   // Maximum date (inclusive)
  allowIso8601: true,    // Accept ISO-8601 string format
  allowTimestamp: true,  // Accept Unix timestamps
  fallback: DateTime(2000), // Default value if missing
)
```

### Enum Fields

Maps string values to Dart enum values.

```dart
enum Role { admin, user, guest }

Field.enumeration<Role>(
  'role',
  values: Role.values.asNameMap(), // Map string values to enum values
  caseSensitive: false,  // Case-insensitive matching
  fallback: Role.guest,  // Default value if missing
)
```

While typically this is intended for actual enum types, you can also use it with any type, as long as you provide a mapping of string values to prebuilt objects of that type.

```dart
class Color {
  final String name;
  Color(this.name);
}

Field.enumeration<Color>(
  'color',
  values: {'red': Color('Red'), 'green': Color('Green'), 'blue': Color('Blue')},
)
```

### RegExp Pattern Fields

Converts string values to RegExp objects.

```dart
Field.pattern(
  'validationPattern',
  full: true,            // Automatically adds ^ and $ anchors
  multiLine: false,      // RegExp multiLine flag
  caseSensitive: true,   // RegExp caseSensitive flag
  unicode: false,        // RegExp unicode flag
  fallback: RegExp(r'.*'), // Default pattern if missing
)
```

### Nested Schema Fields

Validates nested objects using another schema.

```dart
Field.nested(
  'address',
  schema: Address.schema, // Schema for nested object
  fallback: defaultAddress, // Default value if missing
)
```

### Custom Fields

Create fields with custom validation or transformation logic.

You can throw a `TypeError`, `ArgumentError`, or `FormatException` during validation, and JSON Guard will automatically convert them into a `ValidationException` with proper context about where and why they occurred.

```dart
Field.custom<int, String>(
  'code',
  converter: (value) {
	final string = value as String; // Throws TypeError if value is not a String, which is converted to a descriptive error by JSON Guard
    if (!string.startsWith('SW-')) {
      throw ArgumentError('Code must start with SW-'); // Also converted to a descriptive error by JSON Guard
    }
    return int.parse(string.substring(3));
  },
  fallback: 0,
)
```

## Field Modifiers

### Optional Fields

Make a field optional (allows null values):

```dart
Field.string('bio').optional()
```

### List Fields

Validate that a field contains a list of items:

```dart
Field.string('tags').list() // List<String>
Field.nested('users', schema: User.schema).list() // List<User>
```

You can also provide a fallback list:

```dart
Field.string('categories').list(fallback: const [])
```

### Map Fields

Validate that a field contains a map of key-value pairs:

```dart
Field.integer('scores').map() // Map<String, int>
Field.nested('profiles', schema: Profile.schema).map() // Map<String, Profile>
```

You can also provide a fallback map:

```dart
Field.string('metadata').map(fallback: {'version': '1.0'})
```

### Fallback Values

Provide default values for fields that may be missing:

```dart
Field.string('country', fallback: 'Unknown')
```

### Field Aliases

Specify alternative field names to look for in the JSON:

```dart
Field.string('firstName', aliases: ['first_name', 'given_name'])
```

## Advanced Usage

### Schema Composition

Build complex schemas by composing simpler ones:

```dart
class Order {
  final String id;
  final Customer customer;
  final List<Product> products;

  static final schema = Schema(
    fields: [
      Field.string('id'),
      Field.nested('customer', schema: Customer.schema),
      Field.nested('products', schema: Product.schema).list(),
    ],
    constructor: (data) => Order(
      id: data['id'],
      customer: data['customer'],
      products: data['products'],
    ),
  );
}
```

### Handling Collections

Process collections of JSON objects:

```dart
// Parse a JSON array into a List of objects
final users = User.schema.list(jsonArray);

// Parse a JSON object into a Map of objects
final productsByCode = Product.schema.map(productMapJson);
```

### Validating Nested Structures

Create schemas for complex nested data structures:

```dart
class Dashboard {
  final User user;
  final Map<String, List<Metric>> metrics;

  static final schema = Schema(
    fields: [
      Field.nested('user', schema: User.schema),
      Field.nested('metrics', schema: Metric.schema).list().map(),
    ],
    constructor: (data) => Dashboard(
      user: data['user'],
      metrics: data['metrics'],
    ),
  );
}
```

## Complete Examples

### Basic Example

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

class User {
  final String name;
  final int age;
  final String? bio;

  User({required this.name, required this.age, this.bio});

  static final schema = Schema(
    fields: [
      Field.string('name', minLength: 2, maxLength: 50),
      Field.integer('age', min: 0, max: 120),
      Field.string('bio').optional(),
    ],
    constructor: (data) => User(
      name: data['name'],
      age: data['age'],
      bio: data['bio'],
    ),
  );
}

void main() {
  final json = {'name': 'Alice', 'age': 28, 'bio': 'Software engineer'};
  final user = User.schema.fromJson(json);

  final jsonArray = [
    {'name': 'Alice', 'age': 28},
    {'name': 'Bob', 'age': 35, 'bio': 'Designer'},
  ];
  final users = User.schema.list(jsonArray);
}
```

### Nested Objects

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

class Address {
  final String street;
  final String city;
  final String country;

  Address({required this.street, required this.city, required this.country});

  static final schema = Schema(
    fields: [
      Field.string('street'),
      Field.string('city'),
      Field.string('country'),
    ],
    constructor: (data) => Address(
      street: data['street'],
      city: data['city'],
      country: data['country'],
    ),
  );
}

class Contact {
  final String name;
  final List<String> phoneNumbers;
  final Address address;

  Contact({required this.name, required this.phoneNumbers, required this.address});

  static final schema = Schema(
    fields: [
      Field.string('name'),
      Field.string('phone_numbers').list(),
      Field.nested('address', schema: Address.schema),
    ],
    constructor: (data) => Contact(
      name: data['name'],
      phoneNumbers: data['phone_numbers'],
      address: data['address'],
    ),
  );
}

void main() {
  final json = {
    'name': 'John Smith',
    'phone_numbers': ['+1-555-123-4567', '+1-555-987-6543'],
    'address': {
      'street': '123 Main St',
      'city': 'Springfield',
      'country': 'USA'
    }
  };

  final contact = Contact.schema.fromJson(json);
}
```

### Enum Handling

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

enum Role { admin, user, guest }

class Account {
  final String username;
  final Role role;

  Account({required this.username, required this.role});

  static final schema = Schema(
    fields: [
      Field.string('username'),
      Field.enumeration(
        'role',
        values: Role.values.asNameMap(),
        caseSensitive: false,
      ),
    ],
    constructor: (data) => Account(
      username: data['username'],
      role: data['role'],
    ),
  );
}

void main() {
  final json = {
    'username': 'johndoe',
    'role': 'ADMIN',  // Will be converted to Role.admin (case-insensitive)
  };

  final account = Account.schema.fromJson(json);
}
```

### List Validation

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

class Weapon {
  final String name;
  final int damage;

  Weapon({required this.name, required this.damage});

  static final schema = Schema(
    fields: [
      Field.string('name'),
      Field.integer('damage', min: 1),
    ],
    constructor: (data) => Weapon(
      name: data['name'],
      damage: data['damage'],
    ),
  );
}

class Starship {
  final String model;
  final int crewSize;
  final List<String> systems;
  final List<Weapon> weapons;

  Starship({
    required this.model,
    required this.crewSize,
    required this.systems,
    required this.weapons,
  });

  static final schema = Schema(
    fields: [
      Field.string('model'),
      Field.integer('crewSize', min: 1),
      Field.string('systems').list(fallback: ['Basic']),
      Field.nested('weapons', schema: Weapon.schema).list(),
    ],
    constructor: (data) => Starship(
      model: data['model'],
      crewSize: data['crewSize'],
      systems: data['systems'],
      weapons: data['weapons'],
    ),
  );
}

void main() {
  final json = {
    'model': 'X-Wing T-70',
    'crewSize': 1,
    'systems': ['Propulsion', 'Weapons', 'Shields'],
    'weapons': [
      {'name': 'Laser Cannon', 'damage': 50},
      {'name': 'Proton Torpedoes', 'damage': 100}
    ]
  };

  final starship = Starship.schema.fromJson(json);
}
```

### Map Validation

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

class UserRegistry {
  final Map<String, User> users;

  UserRegistry({required this.users});

  static final schema = Schema(
    fields: [
      Field.nested('users', schema: User.schema).map(fallback: const {}),
    ],
    constructor: (data) => UserRegistry(users: data['users']),
  );
}

void main() {
  final json = {
    'users': {
      'john_doe': {
        'name': 'John Doe',
        'age': 30,
      },
      'jane_doe': {
        'name': 'Jane Doe',
        'age': 28,
      }
    }
  };

  final registry = UserRegistry.schema.fromJson(json);
}
```

### RegExp Patterns

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

class NamingPattern {
  final String name;
  final RegExp regex;

  NamingPattern({required this.name, required this.regex});

  bool isValid(String input) {
    return regex.hasMatch(input);
  }

  static final schema = Schema(
    fields: [
      Field.string('name'),
      Field.pattern(
        'regex',
        full: true, // Automatically adds ^ and $ anchors if not present
        fallback: RegExp(r'[a-zA-Z][a-zA-Z0-9_]*'),
      ),
    ],
    constructor: (data) => NamingPattern(
      name: data['name'],
      regex: data['regex'],
    ),
  );
}

void main() {
  final json = {
    'name': 'PascalCase',
    'regex': '[A-Z][a-z0-9]+(?:[A-Z][a-z0-9]+)*',
  };

  final pattern = NamingPattern.schema.fromJson(json);
  print("Pattern matches 'UserAccount': ${pattern.isValid('UserAccount')}");
}
```

## Best Practices

1. **Schema as static members** - Define schemas as static members of your data classes for better organization and reuse.

2. **Validation constraints** - Apply appropriate validation constraints to ensure data integrity.

3. **Error handling** - Always wrap JSON parsing in try-catch blocks to handle validation errors gracefully.

4. **Composition** - Compose complex schemas from simpler ones to build a hierarchy of validations.

5. **Fallback values** - Use fallbacks for fields that might be missing but have sensible defaults.

6. **Field aliases** - Use aliases when handling JSON from different sources that might use different field names.

## Error Handling

JSON Guard throws a single exception type - `ValidationException` - with detailed error messages:

```dart
try {
  final user = User.schema.fromJson(json);
} catch (e) {
  print("$e");
  // e.g., "Validation error at $.age (value: 150, type: int): Value must be at most 120"
}
```

This unifies all validation errors into a consistent format that includes:

- The JSON path where the error occurred (e.g., `$.user.address[0].zipCode`)
- The value that caused the validation error and its type
- A descriptive message explaining what went wrong

The validation exception can represent various error types:
- Missing required fields
- Constraint violations (min/max values, patterns, etc.)
- Type mismatches
- Custom validation errors

## Additional Resources

- [Issue tracker](https://github.com/abrahammurciano/json_guard/issues)
- [GitHub repository](https://github.com/abrahammurciano/json_guard)
- [Example folder](https://github.com/abrahammurciano/json_guard/tree/main/example) with more detailed examples
