import "package:json_guard/json_guard.dart" show Field, JsonTypeException, Schema, ValueValidationException;
import "package:test/test.dart" show contains, expect, fail, group, isA, test;

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
        expect(e.toString(), contains("Map<String, dynamic>"));
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
  });
}
