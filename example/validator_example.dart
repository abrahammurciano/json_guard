// This example demonstrates how to use Validator directly for validating values
// without using Field or Schema classes.

import "package:json_guard/json_guard.dart" show ValidationException, Validator, Schema, Field;

class User {
  final String username;
  final String email;
  final int age;
  final List<String> tags;
  final Map<String, String> preferences;

  User({required this.username, required this.email, required this.age, required this.tags, required this.preferences});

  @override
  String toString() => "User(username: $username, email: $email, age: $age, tags: $tags, preferences: $preferences)";
}

class Address {
  final String street;
  final String city;
  final String zipCode;

  Address({required this.street, required this.city, required this.zipCode});

  @override
  String toString() => "Address(street: $street, city: $city, zipCode: $zipCode)";
}

class Profile {
  final User user;
  final Address address;

  Profile({required this.user, required this.address});

  @override
  String toString() => "Profile(user: $user, address: $address)";
}

void main() {
  print("===== Basic Validator Usage =====");
  demonstrateBasicValidators();

  print("\n===== Combining Validators =====");
  demonstrateCombiningValidators();

  print("\n===== Schema Validation =====");
  demonstrateSchemaValidation();

  print("\n===== Complex Nested Schema =====");
  demonstrateComplexNestedSchema();
}

void demonstrateBasicValidators() {
  // Integer validation with constraints
  final ageValidator = Validator.integer(min: 18, max: 120, fallback: 18);
  try {
    print("Valid age: ${ageValidator.validate(25)}");
    print("Using fallback: ${ageValidator.validate(null)}");

    // This will throw an exception
    print("Too young: ${ageValidator.validate(10)}");
  } on ValidationException catch (e) {
    print("Age validation error: ${e.message}");
  }

  // String validation with length constraints
  final usernameValidator = Validator.string(
    minLength: 3,
    maxLength: 20,
    trim: true,
    pattern: RegExp(r"^[a-zA-Z0-9_]+$"),
  );

  try {
    print('Valid username: ${usernameValidator.validate("john_doe")}');
    print('Trimmed username: ${usernameValidator.validate("  alice_123  ")}');

    // This will throw an exception
    print('Invalid username: ${usernameValidator.validate("a!")}');
  } on ValidationException catch (e) {
    print("Username validation error: ${e.message}");
  }

  // Enum validation
  final roleValidator = Validator.enumeration<String>(
    values: {"admin": "ADMIN", "user": "USER", "guest": "GUEST"},
    caseSensitive: false,
    fallback: "USER",
  );

  try {
    print('Valid role: ${roleValidator.validate("admin")}');
    print('Case insensitive: ${roleValidator.validate("GUEST")}');
    print("Using fallback: ${roleValidator.validate(null)}");

    // This will throw an exception
    print('Invalid role: ${roleValidator.validate("moderator")}');
  } on ValidationException catch (e) {
    print("Role validation error: ${e.message}");
  }

  // DateTime validation
  final birthdateValidator = Validator.datetime(
    min: DateTime(1900),
    max: DateTime.now(),
    allowIso8601: true,
    allowTimestamp: true,
  );

  try {
    print('Valid date (ISO): ${birthdateValidator.validate("1990-01-01")}');
    print("Valid date (timestamp): ${birthdateValidator.validate(946684800000)}"); // 2000-01-01

    // This will throw an exception
    print('Future date: ${birthdateValidator.validate("2050-01-01")}');
  } on ValidationException catch (e) {
    print("Date validation error: ${e.message}");
  }
}

void demonstrateCombiningValidators() {
  // Optional validators
  final optionalAgeValidator = Validator.integer(min: 18).optional();

  print("Required age with null: ${tryValidate(() => Validator.integer().validate(null))}");
  print("Optional age with null: ${optionalAgeValidator.validate(null)}");
  print("Optional age with value: ${optionalAgeValidator.validate(25)}");

  // List validators
  final tagsValidator = Validator.string(minLength: 2, maxLength: 10).list(fallback: []);

  try {
    print('Valid tags: ${tagsValidator.validate(["dart", "json", "validation"])}');
    print("Empty list: ${tagsValidator.validate([])}");
    print("Using fallback: ${tagsValidator.validate(null)}");

    // This will throw an exception
    print('Invalid tag in list: ${tagsValidator.validate(["ok", "x", "toolong....."])}');
  } on ValidationException catch (e) {
    print("Tags validation error: ${e.message}");
  }

  // Map validators
  final preferencesValidator = Validator.string().map(fallback: {"theme": "light"});

  try {
    print('Valid preferences: ${preferencesValidator.validate({'theme': 'dark', 'fontSize': '14px'})}');
    print("Empty map: ${preferencesValidator.validate({})}");
    print("Using fallback: ${preferencesValidator.validate(null)}");

    // This will throw an exception - non-string values
    print(
      'Invalid preferences: ${preferencesValidator.validate({
        'theme': 'dark',
        'fontSize': 14, // Should be a string
      })}',
    );
  } on ValidationException catch (e) {
    print("Preferences validation error: ${e.message}");
  }

  // Chaining multiple transformations
  final optionalTagsValidator = Validator.string(minLength: 2).list().optional();

  print('Optional tags with value: ${optionalTagsValidator.validate(["dart", "flutter"])}');
  print("Optional tags with null: ${optionalTagsValidator.validate(null)}");
}

void demonstrateSchemaValidation() {
  // Create a schema for an Address
  final addressSchema = Schema<Address>(
    fields: [
      Field.string("street", minLength: 3),
      Field.string("city", minLength: 2),
      Field.string("zipCode", pattern: RegExp(r"^\d{5}$")),
    ],
    constructor: (data) => Address(street: data["street"], city: data["city"], zipCode: data["zipCode"]),
  );

  // Create a validator using the schema
  final addressValidator = Validator.schema(schema: addressSchema);

  try {
    final validAddressJson = {"street": "123 Main St", "city": "New York", "zipCode": "10001"};

    final address = addressValidator.validate(validAddressJson);
    print("Valid address: $address");

    // This will throw an exception - invalid zip code
    final invalidAddressJson = {
      "street": "456 Broadway",
      "city": "Boston",
      "zipCode": "ABC", // Invalid format
    };

    print("Invalid address: ${addressValidator.validate(invalidAddressJson)}");
  } on ValidationException catch (e) {
    print("Address validation error: ${e.message} at ${e.path}");
  }
}

void demonstrateComplexNestedSchema() {
  // Create schema for User
  final userSchema = Schema<User>(
    fields: [
      Field.string("username", minLength: 3, maxLength: 20),
      Field.string("email", pattern: RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$")),
      Field.integer("age", min: 13),
      Field.string("tag", minLength: 1).list(fallback: []),
      Field.string("preference").map(fallback: {}),
    ],
    constructor: (data) => User(
      username: data["username"],
      email: data["email"],
      age: data["age"],
      tags: data["tag"],
      preferences: data["preference"],
    ),
  );

  // Create schema for Address
  final addressSchema = Schema<Address>(
    fields: [
      Field.string("street", minLength: 3),
      Field.string("city", minLength: 2),
      Field.string("zipCode", pattern: RegExp(r"^\d{5}$")),
    ],
    constructor: (data) => Address(street: data["street"], city: data["city"], zipCode: data["zipCode"]),
  );

  // Create nested schema for Profile
  final profileSchema = Schema<Profile>(
    fields: [
      Field.nested("user", schema: userSchema),
      Field.nested("address", schema: addressSchema),
    ],
    constructor: (data) => Profile(user: data["user"], address: data["address"]),
  );

  // Create a validator using the nested schema
  final profileValidator = Validator.schema(schema: profileSchema);

  try {
    final validProfileJson = {
      "user": {
        "username": "john_doe",
        "email": "john@example.com",
        "age": 30,
        "tag": ["developer", "dart"],
        "preference": {"theme": "dark", "notifications": "on"},
      },
      "address": {"street": "123 Main St", "city": "New York", "zipCode": "10001"},
    };

    final profile = profileValidator.validate(validProfileJson);
    print("Valid profile: $profile");

    // This will throw an exception - invalid email
    final invalidProfileJson = {
      "user": {
        "username": "alice",
        "email": "invalid-email", // Invalid email format
        "age": 25,
        "tag": ["designer"],
        "preference": {"theme": "light"},
      },
      "address": {"street": "456 Broadway", "city": "Boston", "zipCode": "20001"},
    };

    print("Invalid profile: ${profileValidator.validate(invalidProfileJson)}");
  } on ValidationException catch (e) {
    print("Profile validation error: ${e.message} at ${e.path}");
  }
}

// Helper function to safely try validation
T? tryValidate<T>(T Function() validationFunc) {
  try {
    return validationFunc();
  } on ValidationException {
    return null;
  }
}
