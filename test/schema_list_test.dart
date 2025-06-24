import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show contains, equals, expect, fail, group, test;

import "test_utils.dart" show TestModel;

void main() {
  group("Schema.list tests", () {
    test("validates a list of JSON objects", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Leia Organa", "age": 23},
        {"name": "Han Solo", "age": 32},
      ];

      final results = schema.list(jsonList);

      expect(results.length, equals(3));
      expect(results[0].name, equals("Luke Skywalker"));
      expect(results[0].age, equals(23));
      expect(results[1].name, equals("Leia Organa"));
      expect(results[1].age, equals(23));
      expect(results[2].name, equals("Han Solo"));
      expect(results[2].age, equals(32));
    });

    test("throws ValidationException with correct path when list item is not a map", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        "not a map",
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("not a map"));
        expect(e.path.toString(), equals("\$[1]"));
      }
    });

    test("throws ValidationException with correct path when field is missing", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Leia Organa"}, // missing age
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.path.toString(), equals("\$[1].age"));
      }
    });

    test("throws ValidationException with correct path on validation failure", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age", min: 18)],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Grogu", "age": 5}, // too young
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("5"));
        expect(e.toString(), contains("at least"));
        expect(e.path.toString(), equals("\$[1].age"));
      }
    });

    test("throws ValidationException with correct path on converter error", () {
      final schema = Schema(
        fields: [
          Field.string("name"),
          Field.custom<int, String>(
            "code",
            converter: (value) {
              if (!value.startsWith("SW-")) {
                throw ArgumentError("Code must start with SW-");
              }
              return int.parse(value.substring(3));
            },
          ),
        ],
        constructor: (data) => data,
      );

      final jsonList = [
        {"name": "Luke Skywalker", "code": "SW-123"},
        {"name": "Darth Vader", "code": "DV-456"}, // invalid prefix
        {"name": "Han Solo", "code": "SW-789"},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("DV-456"));
        expect(e.toString(), contains("Code must start with SW-"));
        expect(e.path.toString(), equals("\$[1].code"));
      }
    });

    test("throws ValidationException with correct path on schema constructor error", () {
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

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Clone", "age": -5}, // negative age
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains({"name": "Clone", "age": -5}.toString()));
        expect(e.path.toString(), equals("\$[1]"));
        expect(e.toString(), contains("Age cannot be negative"));
      }
    });
  });
}
