# JSON Guard

JSON Guard is a lightweight library for validating, transforming, and parsing JSON data in Dart. It provides a type-safe approach to working with JSON without requiring code generation or reflection.

## Features

- **Type-safe parsing** - Convert JSON to your domain objects with robust type checking
- **Validation** - Ensure values meet your constraints before constructing objects
- **Detailed error reporting** - Get precise error messages with JSON paths to quickly identify issues
- **Zero reflection** - No reflection or code generation required
- **Composable schemas** - Build complex schemas from simpler building blocks

## Getting started

Add JSON Guard to your `pubspec.yaml`:

```yaml
dependencies:
  json_guard: ^1.0.0
```

Then run:

```
dart pub get
```

## Usage

### Basic example

Define a class and create a schema for validating and parsing JSON:

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

class User {
  final String name;
  final int age;
  final String? bio;

  User({required this.name, required this.age, this.bio});

  // Create a schema that validates and constructs User objects
  static final schema = Schema(
    fields: [
      Field.string('name', minLength: 2, maxLength: 50).field(),
      Field.integer('age', min: 0, max: 120).field(),
      Field.string('bio').optional().field(),
    ],
    constructor: (data) => User(
      name: data['name'],
      age: data['age'],
      bio: data['bio'],
    ),
  );
}

// Parse a JSON object
final json = {'name': 'Alice', 'age': 28, 'bio': 'Software engineer'};

final user = User.schema.fromJson(json);

// Parse a JSON array
final jsonArray = [
  {'name': 'Alice', 'age': 28},
  {'name': 'Bob', 'age': 35, 'bio': 'Designer'},
];

final users = User.schema.many(jsonArray);
```

### Advanced examples

#### Lists and nested objects

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

class Address {
  final String street;
  final String city;
  final String country;

  Address({required this.street, required this.city, required this.country});

  // Create a schema for Address
  final schema = Schema(
    fields: [
    	Field.string('street').field(),
    	Field.string('city').field(),
    	Field.string('country').field(),
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

  // Create a schema for Contact with a nested Address and a list of phone numbers
  final schema = Schema(
    fields: [
      Field.string('name').field(),
      Field.string('phone_numbers').many().field(),
      Field.nested('address', schema: Address.schema).field(),
    ],
    constructor: (data) => Contact(
      name: data['name'],
      phoneNumbers: data['phone_numbers'],
      address: data['address'],
    ),
  );
}

// Parse a JSON object with nested structure
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
```

#### Enum mapping

```dart
import 'package:json_guard/json_guard.dart' show Field, Schema;

enum Role { admin, user, guest }

class Account {
  final String username;
  final Role role;

  Account({required this.username, required this.role});

  final schema = Schema(
    fields: [
      Field.string('username').field(),
      Field.enumeration('role', values: Role.values.asNameMap()).field(),
    ],
    constructor: (data) => Account(
      username: data['username'],
      role: data['role'],
    ),
  );
}

final json = {
  'username': 'johndoe',
  'role': 'ADMIN',  // Will be converted to Role.admin (case-insensitive)
};

final account = Account.schema.fromJson(json);
```

## Additional information

JSON Guard focuses on validation and parsing of JSON data. It's designed to be simple and efficient, without requiring code generation or reflection. It provides a fluent API for defining schemas and field validations.

For more examples, check out the `/example` folder in the repository.

- [Issue tracker](https://github.com/abrahammurciano/json_guard/issues)
- [GitHub repository](https://github.com/abrahammurciano/json_guard)
