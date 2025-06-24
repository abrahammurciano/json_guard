import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show equals, expect, group, test, throwsA, TypeMatcher;

void main() {
  group("Empty dynamic collection handling", () {
    test("accepts empty dynamic list for typed List field", () {
      final schema = Schema(fields: [Field.string("name"), Field.string("tags").list()], constructor: (data) => data);

      final data = {"name": "Test Item", "tags": <dynamic>[]};

      final result = schema.fromJson(data);
      expect(result["name"], equals("Test Item"));
      expect(result["tags"], equals(<String>[]));
    });

    test("accepts empty dynamic map for typed Map field", () {
      final schema = Schema(fields: [Field.string("name"), Field.integer("scores").map()], constructor: (data) => data);

      final data = {"name": "Test Item", "scores": <dynamic, dynamic>{}};

      final result = schema.fromJson(data);
      expect(result["name"], equals("Test Item"));
      expect(result["scores"], equals(<String, int>{}));
    });

    test("nested schema handles empty dynamic collections", () {
      final itemSchema = Schema(
        fields: [Field.string("name"), Field.string("category").list()],
        constructor: (data) => data,
      );

      final schema = Schema(
        fields: [
          Field.string("title"),
          Field.nested("item", schema: itemSchema),
        ],
        constructor: (data) => data,
      );

      final data = {
        "title": "Collection",
        "item": {"name": "Test Item", "category": <dynamic>[]},
      };

      final result = schema.fromJson(data);
      expect(result["title"], equals("Collection"));
      expect(result["item"]["name"], equals("Test Item"));
      expect(result["item"]["category"], equals(<String>[]));
    });

    test("rejects non-empty lists with incorrect element type", () {
      final schema = Schema(fields: [Field.string("tags").list()], constructor: (data) => data);

      final data = {
        "tags": [1, 2, 3],
      };

      expect(() => schema.fromJson(data), throwsA(TypeMatcher<ValidationException>()));
    });
  });
}
