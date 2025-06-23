import "package:json_guard/json_guard.dart" show Field, Schema;
import "package:test/test.dart" show equals, expect, group, isNull, test;

void main() {
  group("Optional fields and fallbacks", () {
    test("handles optional fields", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.string("title").optional().field()],
        constructor: (data) => data,
      );

      final dataWithTitle = {"name": "Luke Skywalker", "title": "Jedi Knight"};
      final dataWithoutTitle = {"name": "Luke Skywalker"};

      final result1 = schema.fromJson(dataWithTitle);
      final result2 = schema.fromJson(dataWithoutTitle);

      expect(result1["name"], equals("Luke Skywalker"));
      expect(result1["title"], equals("Jedi Knight"));

      expect(result2["name"], equals("Luke Skywalker"));
      expect(result2["title"], isNull);
    });

    test("uses fallback values", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.string("species", fallback: "Human").field(),
          Field.integer("age", fallback: 30).field(),
        ],
        constructor: (data) => data,
      );

      final data = {"name": "Luke Skywalker"};

      final result = schema.fromJson(data);
      expect(result["name"], equals("Luke Skywalker"));
      expect(result["species"], equals("Human"));
      expect(result["age"], equals(30));
    });

    test("uses aliases with fallbacks", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name", aliases: ["fullName"]).field(),
          Field.string("species", aliases: ["race"], fallback: "Human").field(),
        ],
        constructor: (data) => data,
      );

      final data = {"fullName": "Luke Skywalker"};

      final result = schema.fromJson(data);
      expect(result["name"], equals("Luke Skywalker"));
      expect(result["species"], equals("Human"));
    });
  });
}
