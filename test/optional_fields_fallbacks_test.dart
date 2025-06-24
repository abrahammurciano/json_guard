import "package:json_guard/json_guard.dart" show Field, Schema;
import "package:test/test.dart" show equals, expect, group, isNull, test;

void main() {
  group("Optional fields and fallbacks", () {
    test("handles optional fields", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.string("title").optional()],
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
      final schema = Schema(
        fields: [
          Field.string("name"),
          Field.string("species", fallback: "Human"),
          Field.integer("age", fallback: 30),
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
      final schema = Schema(
        fields: [
          Field.string("name", aliases: ["fullName"]),
          Field.string("species", aliases: ["race"], fallback: "Human"),
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
