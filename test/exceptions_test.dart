import "package:json_guard/json_guard.dart"
    show
        Field,
        JsonTypeException,
        Schema,
        ValueValidationException,
        ArgumentErrorValidationException,
        ValidationException;
import "package:test/test.dart" show equals, contains, expect, fail, group, isA, isNull, test;

import "test_utils.dart" show TestModel;

void main() {
  group("ValidationException", () {
    test("includes error details", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.integer("age", min: 18).field()],
        constructor: (data) => data,
      );

      try {
        schema.fromJson({"age": 15});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValueValidationException>());
        expect(e.toString(), contains("15"));
        expect(e.toString(), contains("at least"));
        expect(e.toString(), contains("18"));
        expect(e.toString(), contains("age"));
      }
    });

    test("error indicates path in nested objects", () {
      final addressSchema = Schema<Map<String, dynamic>>(
        fields: [Field.integer("zip").field()],
        constructor: (data) => data,
      );

      final personSchema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.nested("address", schema: addressSchema).field(),
        ],
        constructor: (data) => data,
      );

      try {
        personSchema.fromJson({
          "name": "Luke Skywalker",
          "address": {
            "zip": "not a number", // incorrect type
          },
        });
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValidationException>());
        expect(e.toString(), contains("\$.address.zip"));
      }
    });
  });

  group("JsonTypeException", () {
    test("thrown for incorrect JSON type", () {
      final schema = Schema<Map<String, dynamic>>(fields: [Field.string("name").field()], constructor: (data) => data);

      try {
        schema.fromJson("not an object");
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<JsonTypeException>());
        expect(e.toString(), contains("not an object"));
        expect(e.toString(), contains("String"));
        expect(e.toString(), contains("Map"));
      }
    });
  });

  group("FieldMissingException", () {
    test("thrown for missing required field", () {
      // Create a schema with fields but no fallbacks
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => data,
      );

      try {
        schema.fromJson({"name": "Luke Skywalker"});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e.toString(), contains("missing"));
      }
    });
  });

  group("ValueValidationException", () {
    test("thrown for constraint violations", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name", minLength: 5).field()],
        constructor: (data) => data,
      );

      try {
        schema.fromJson({"name": "Luke"});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValueValidationException>());
        expect(e.toString(), contains("Luke"));
        expect(e.toString(), contains("length"));
        expect(e.toString(), contains("name"));
      }
    });

    test("error indicates path in nested objects", () {
      final addressSchema = Schema<Map<String, dynamic>>(
        fields: [Field.integer("zip", min: 10000, max: 99999).field()],
        constructor: (data) => data,
      );

      final personSchema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.nested("address", schema: addressSchema).field(),
        ],
        constructor: (data) => data,
      );

      try {
        personSchema.fromJson({
          "name": "Luke Skywalker",
          "address": {
            "zip": 123, // too short
          },
        });
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValueValidationException>());
        expect(e.toString(), contains("123"));
        expect(e.toString(), contains("at least 10000"));
        expect(e.toString(), contains("address.zip"));
      }
    });
    test("thrown for incorrect value type", () {
      final schema = Schema<Map<String, dynamic>>(fields: [Field.integer("age").field()], constructor: (data) => data);

      try {
        schema.fromJson({"age": "not a number"});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValueValidationException>());
        expect(e.toString(), contains("age"));
      }
    });
  });

  group("ArgumentErrorValidationException tests", () {
    test("captures field converter ArgumentError with correct information", () {
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

      final invalidData = {"name": "Luke Skywalker", "code": "ABC-123"};

      try {
        schema.fromJson(invalidData);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ArgumentErrorValidationException catch (e) {
        expect(e.value, equals("ABC-123"));
        expect(e.reason, equals("Code must start with SW-"));
        expect(e.field?.name, equals("code"));
        expect(e.path.toString(), equals("\$.code"));
        expect(e.toString(), contains("Field 'code'"));
        expect(e.toString(), contains("Code must start with SW-"));
      }
    });

    test("captures schema constructor ArgumentError with correct information", () {
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

      final invalidData = {"name": "Luke Skywalker", "age": -5};

      try {
        schema.fromJson(invalidData);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ArgumentErrorValidationException catch (e) {
        expect(e.value, equals(invalidData));
        expect(e.reason, equals("Age cannot be negative"));
        expect(e.field, isNull);
        expect(e.path.toString(), equals("\$"));
        expect(e.toString(), contains("Age cannot be negative"));
        expect(e.toString(), contains("at \$"));
      }
    });

    test("captures ArgumentError in nested schema with correct path", () {
      final nestedSchema = Schema<Map<String, dynamic>>(
        fields: [
          Field.custom<int, String>(
            "id",
            converter: (value) {
              if (value.length < 3) {
                throw ArgumentError("ID must be at least 3 characters");
              }
              return int.parse(value);
            },
          ).field(),
        ],
        constructor: (data) => data,
      );

      final parentSchema = Schema<Map<String, dynamic>>(
        fields: [Field.nested<Map<String, dynamic>>("user", schema: nestedSchema).field()],
        constructor: (data) => data,
      );

      final invalidData = {
        "user": {"id": "12"},
      };

      try {
        parentSchema.fromJson(invalidData);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ArgumentErrorValidationException catch (e) {
        expect(e.value, equals("12"));
        expect(e.reason, equals("ID must be at least 3 characters"));
        expect(e.field?.name, equals("id"));
        expect(e.path.toString(), equals("\$.user.id"));
      }
    });
  });
}
