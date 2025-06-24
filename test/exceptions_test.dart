import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show equals, contains, expect, fail, group, isA, test;

import "test_utils.dart" show TestModel;

void main() {
  group("ValidationException", () {
    test("includes error details", () {
      final schema = Schema(fields: [Field.integer("age", min: 18)], constructor: (data) => data);

      try {
        schema.fromJson({"age": 15});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValidationException>());
        expect(e.toString(), contains("15"));
        expect(e.toString(), contains("at least"));
        expect(e.toString(), contains("18"));
        expect(e.toString(), contains("age"));
      }
    });

    test("error indicates path in nested objects", () {
      final addressSchema = Schema(fields: [Field.integer("zip")], constructor: (data) => data);

      final personSchema = Schema(
        fields: [
          Field.string("name"),
          Field.nested("address", schema: addressSchema),
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

    test("thrown for incorrect JSON type", () {
      final schema = Schema(fields: [Field.string("name")], constructor: (data) => data);

      try {
        schema.fromJson("not an object");
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValidationException>());
        expect(e.toString(), contains("not an object"));
        expect(e.toString(), contains("String"));
        expect(e.toString(), contains("Map"));
      }
    });

    test("thrown for missing required field", () {
      // Create a schema with fields but no fallbacks
      final schema = Schema(fields: [Field.string("name"), Field.integer("age")], constructor: (data) => data);

      try {
        schema.fromJson({"name": "Luke Skywalker"});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e.toString(), contains("Missing required field"));
      }
    });

    test("thrown for constraint violations", () {
      final schema = Schema(fields: [Field.string("name", minLength: 5)], constructor: (data) => data);

      try {
        schema.fromJson({"name": "Luke"});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValidationException>());
        expect(e.toString(), contains("Luke"));
        expect(e.toString(), contains("length"));
        expect(e.toString(), contains("name"));
      }
    });

    test("error indicates path in nested objects", () {
      final addressSchema = Schema(fields: [Field.integer("zip", min: 10000, max: 99999)], constructor: (data) => data);

      final personSchema = Schema(
        fields: [
          Field.string("name"),
          Field.nested("address", schema: addressSchema),
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
        expect(e, isA<ValidationException>());
        expect(e.toString(), contains("123"));
        expect(e.toString(), contains("at least 10000"));
        expect(e.toString(), contains("address.zip"));
      }
    });

    test("thrown for incorrect value type", () {
      final schema = Schema(fields: [Field.integer("age")], constructor: (data) => data);

      try {
        schema.fromJson({"age": "not a number"});
        fail("Should have thrown exception");
      } catch (e) {
        expect(e, isA<ValidationException>());
        expect(e.toString(), contains("age"));
      }
    });
  });

  group("ArgumentError conversion", () {
    test("captures field converter ArgumentError with correct information", () {
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

      final invalidData = {"name": "Luke Skywalker", "code": "ABC-123"};

      try {
        schema.fromJson(invalidData);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("ABC-123"));
        expect(e.toString(), contains("Code must start with SW-"));
        expect(e.path.toString(), equals("\$.code"));
      }
    });

    test("captures schema constructor ArgumentError with correct information", () {
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

      final invalidData = {"name": "Luke Skywalker", "age": -5};

      try {
        schema.fromJson(invalidData);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains(invalidData.toString()));
        expect(e.toString(), contains("Age cannot be negative"));
        expect(e.path.toString(), equals("\$"));
        expect(e.toString(), contains("Age cannot be negative"));
        expect(e.toString(), contains("at \$"));
      }
    });

    test("captures ArgumentError in nested schema with correct path", () {
      final nestedSchema = Schema(
        fields: [
          Field.custom<int, String>(
            "id",
            converter: (value) {
              if (value.length < 3) {
                throw ArgumentError("ID must be at least 3 characters");
              }
              return int.parse(value);
            },
          ),
        ],
        constructor: (data) => data,
      );

      final parentSchema = Schema(
        fields: [Field.nested("user", schema: nestedSchema)],
        constructor: (data) => data,
      );

      final invalidData = {
        "user": {"id": "12"},
      };

      try {
        parentSchema.fromJson(invalidData);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("12"));
        expect(e.toString(), contains("ID must be at least 3 characters"));
        expect(e.toString(), contains("id"));
        expect(e.path.toString(), equals("\$.user.id"));
      }
    });
  });

  group("TypeError conversion", () {
    test("converts TypeError from cast in converter to ValidationException", () {
      final schema = Schema(
        fields: [Field.custom<int, dynamic>("value", converter: (value) => (value as String).length)],
        constructor: (data) => data,
      );

      try {
        schema.fromJson({"value": 42});
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("type 'int' is not a subtype of type 'String'"));
        expect(e.toString(), contains("value"));
        expect(e.path.toString(), equals("\$.value"));
      }
    });

    test("converts TypeError from cast in constructor to ValidationException", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.string("data")],
        constructor: (data) {
          return TestModel(name: data["name"], age: (data["data"] as Map<String, dynamic>)["age"]);
        },
      );

      try {
        schema.fromJson({"name": "Luke", "data": "not a map"});
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("type 'String' is not a subtype of type 'Map<String, dynamic>'"));
        expect(e.path.toString(), equals("\$"));
      }
    });

    test("converts TypeError in nested schema cast with correct path", () {
      final nestedSchema = Schema(
        fields: [Field.custom<int, dynamic>("config", converter: (value) => (value as List<dynamic>)[0])],
        constructor: (data) => data,
      );

      final parentSchema = Schema(
        fields: [Field.nested("user", schema: nestedSchema)],
        constructor: (data) => data,
      );

      final invalidData = {
        "user": {
          "config": {"not": "a list"},
        },
      };

      try {
        parentSchema.fromJson(invalidData);
        fail("Should have thrown ValidationException");
      } on ValidationException catch (e) {
        expect(e.toString(), contains("type '_Map<String, String>' is not a subtype of type 'List<dynamic>'"));
        expect(e.toString(), contains("config"));
        expect(e.path.toString(), equals("\$.user.config"));
      }
    });
  });
}
