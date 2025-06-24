import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, test, throwsA;

import "test_utils.dart" show TestModel;

void main() {
  group("Integer field validations", () {
    test("enforces min constraint", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age", min: 18)],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke Skywalker", "age": 23};
      final invalidData = {"name": "Grogu", "age": 5};

      expect(schema.fromJson(validData).age, equals(23));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });

    test("enforces max constraint", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age", max: 100)],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke Skywalker", "age": 23};
      final invalidData = {"name": "Yoda", "age": 900};

      expect(schema.fromJson(validData).age, equals(23));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });

    test("supports string-to-integer conversion", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker", "age": "23"};
      expect(schema.fromJson(data).age, equals(23));
    });

    test("rejects invalid integers", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => TestModel(name: data["name"], age: data["age"]),
      );

      final invalidData = {"name": "Luke Skywalker", "age": "twenty-three"};
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });
  });
}
