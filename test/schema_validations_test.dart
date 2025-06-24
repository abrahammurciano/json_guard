import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, test, throwsA;

import "test_utils.dart" show TestModel;

void main() {
  group("Schema validations", () {
    test("validates basic types", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker", "age": 23};
      final result = schema.fromJson(data);

      expect(result.name, equals("Luke Skywalker"));
      expect(result.age, equals(23));
    });

    test("throws on missing fields", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker"};

      expect(() => schema.fromJson(data), throwsA(TypeMatcher<ValidationException>()));
    });

    test("uses field fallbacks", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age", fallback: 20)],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker"};
      final result = schema.fromJson(data);

      expect(result.name, equals("Luke Skywalker"));
      expect(result.age, equals(20));
    });

    test("uses field aliases", () {
      final schema = Schema(
        fields: [
          Field.string("name", aliases: ["fullName", "characterName"]),
          Field.integer("age", aliases: ["years"]),
        ],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final data = {"characterName": "Luke Skywalker", "years": 23};
      final result = schema.fromJson(data);

      expect(result.name, equals("Luke Skywalker"));
      expect(result.age, equals(23));
    });

    test("catches ArgumentError in constructor and throws ValidationException", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) {
          final age = data["age"] as int;
          if (age < 0) {
            throw ArgumentError("Age cannot be negative");
          }
          return TestModel(name: data["name"], age: age);
        },
      );

      final validData = {"name": "Luke Skywalker", "age": 23};
      final invalidData = {"name": "Luke Skywalker", "age": -5};

      expect(schema.fromJson(validData).age, equals(23));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });
  });
}
