import "package:json_guard/json_guard.dart"
    show
        Field,
        Schema,
        ValueValidationException,
        ArgumentErrorValidationException,
        FieldMissingException,
        WrongJsonTypeException;
import "package:test/test.dart" show contains, equals, expect, fail, group, test;

import "test_utils.dart" show TestModel;

void main() {
  group("Schema.list tests", () {
    test("validates a list of JSON objects", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
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

    test("throws JsonTypeException with correct path when list item is not a map", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        "not a map",
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown WrongJsonTypeException");
      } on WrongJsonTypeException catch (e) {
        expect(e.data, equals("not a map"));
        expect(e.path.toString(), equals("\$[1]"));
      }
    });

    test("throws FieldMissingException with correct path when field is missing", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Leia Organa"}, // missing age
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown FieldMissingException");
      } on FieldMissingException catch (e) {
        expect(e.field?.name, equals("age"));
        expect(e.path.toString(), equals("\$[1].age"));
      }
    });

    test("throws ValueValidationException with correct path on validation failure", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name").field(), Field.integer("age", min: 18).field()],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Grogu", "age": 5}, // too young
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ValueValidationException");
      } on ValueValidationException catch (e) {
        expect(e.value, equals(5));
        expect(e.field?.name, equals("age"));
        expect(e.path.toString(), equals("\$[1].age"));
        expect(e.reason, contains("at least"));
      }
    });

    test("throws ArgumentErrorValidationException with correct path on converter error", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.custom<int, String>(
            "code",
            converter: (value) {
              if (!value.startsWith("SW-")) {
                throw ArgumentError("Code must start with SW-");
              }
              return int.parse(value.substring(3));
            },
          ).field(),
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
        fail("Should have thrown ArgumentErrorValidationException");
      } on ArgumentErrorValidationException catch (e) {
        expect(e.value, equals("DV-456"));
        expect(e.field?.name, equals("code"));
        expect(e.path.toString(), equals("\$[1].code"));
        expect(e.reason, equals("Code must start with SW-"));
      }
    });

    test("throws ArgumentErrorValidationException with correct path on schema constructor error", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
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
        fail("Should have thrown ArgumentErrorValidationException");
      } on ArgumentErrorValidationException catch (e) {
        expect(e.value, equals({"name": "Clone", "age": -5}));
        expect(e.path.toString(), equals("\$[1]"));
        expect(e.reason, equals("Age cannot be negative"));
      }
    });
  });
}
