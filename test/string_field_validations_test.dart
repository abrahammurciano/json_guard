import "package:json_guard/json_guard.dart" show Field, Schema, ValueValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, test, throwsA;

import "test_utils.dart" show TestModel;

void main() {
  group("String field validations", () {
    test("enforces minLength constraint", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name", minLength: 3).field(), Field.integer("age").field()],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "R2", "age": 30};

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("enforces maxLength constraint", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name", maxLength: 10).field(), Field.integer("age").field()],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "Luke Skywalker of Tatooine", "age": 23};

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("applies trim option", () {
      final schema = Schema<TestModel>(
        fields: [Field.string("name", trim: true).field(), Field.integer("age").field()],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final data = {"name": "  Luke Skywalker  ", "age": 23};
      expect(schema.fromJson(data).name, equals("Luke Skywalker"));
    });

    test("validates pattern constraint", () {
      final schema = Schema<TestModel>(
        fields: [
          Field.string("name", pattern: RegExp(r"^[A-Z][a-z]+$")).field(),
          Field.integer("age").field(),
        ],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "luke", "age": 23}; // lowercase first letter

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("validates options constraint", () {
      final schema = Schema<TestModel>(
        fields: [
          Field.string("name", options: {"Luke", "Leia", "Han"}).field(),
          Field.integer("age").field(),
        ],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "Darth Vader", "age": 45};

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });
  });
}
