import "package:json_guard/json_guard.dart" show Field, Schema, ValueValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, test, throwsA;

void main() {
  group("Nested schema validations", () {
    test("validates nested objects", () {
      final locationSchema = Schema<Map<String, dynamic>>(
        fields: [Field.integer("x").field(), Field.integer("y").field()],
        constructor: (data) => data,
      );

      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.nested("location", schema: locationSchema).field(),
        ],
        constructor: (data) => data,
      );

      final data = {
        "name": "Tatooine",
        "location": {"x": 10, "y": 20},
      };

      final result = schema.fromJson(data);
      expect(result["name"], equals("Tatooine"));
      expect(result["location"]["x"], equals(10));
      expect(result["location"]["y"], equals(20));
    });

    test("validates nested object constraints", () {
      final locationSchema = Schema<Map<String, dynamic>>(
        fields: [Field.integer("x", min: 0).field(), Field.integer("y", min: 0).field()],
        constructor: (data) => data,
      );

      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.nested("location", schema: locationSchema).field(),
        ],
        constructor: (data) => data,
      );

      final validData = {
        "name": "Tatooine",
        "location": {"x": 10, "y": 20},
      };

      final invalidData = {
        "name": "Tatooine",
        "location": {
          "x": -10, // negative, violates min constraint
          "y": 20,
        },
      };

      expect(schema.fromJson(validData)["location"]["x"], equals(10));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("handles deeply nested objects", () {
      final coordinateSchema = Schema<Map<String, dynamic>>(
        fields: [Field.integer("x").field(), Field.integer("y").field()],
        constructor: (data) => data,
      );

      final sectorSchema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.nested("center", schema: coordinateSchema).field(),
        ],
        constructor: (data) => data,
      );

      final systemSchema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.integer("planets").field(),
          Field.nested("sector", schema: sectorSchema).field(),
        ],
        constructor: (data) => data,
      );

      final data = {
        "name": "Tatoo",
        "planets": 2,
        "sector": {
          "name": "Arkanis",
          "center": {"x": 6582, "y": 5724},
        },
      };

      final result = systemSchema.fromJson(data);
      expect(result["name"], equals("Tatoo"));
      expect(result["planets"], equals(2));
      expect(result["sector"]["name"], equals("Arkanis"));
      expect(result["sector"]["center"]["x"], equals(6582));
    });
  });
}
