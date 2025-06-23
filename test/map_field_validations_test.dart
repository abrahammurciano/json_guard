import "package:json_guard/json_guard.dart" show Field, Schema, ValueValidationException, JsonTypeException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, isNull, test, throwsA;

void main() {
  group("Map field validations", () {
    test("validates maps of primitives", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.integer("scores").map().field()],
        constructor: (data) => data,
      );

      final data = {
        "name": "Skills Assessment",
        "scores": {"piloting": 90, "combat": 85, "diplomacy": 65},
      };

      final result = schema.fromJson(data);
      expect(result["name"], equals("Skills Assessment"));
      expect(result["scores"]["piloting"], equals(90));
      expect(result["scores"]["combat"], equals(85));
      expect(result["scores"]["diplomacy"], equals(65));
    });

    test("validates maps of complex objects", () {
      final characterSchema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => data,
      );

      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("faction").field(),
          Field.nested("members", schema: characterSchema).map().field(),
        ],
        constructor: (data) => data,
      );

      final data = {
        "faction": "Rebellion",
        "members": {
          "leader": {"name": "Leia Organa", "age": 25},
          "pilot": {"name": "Han Solo", "age": 30},
          "jedi": {"name": "Luke Skywalker", "age": 23},
        },
      };

      final result = schema.fromJson(data);
      expect(result["faction"], equals("Rebellion"));
      expect(result["members"]["leader"]["name"], equals("Leia Organa"));
      expect(result["members"]["pilot"]["age"], equals(30));
      expect(result["members"]["jedi"]["name"], equals("Luke Skywalker"));
    });

    test("validates map value constraints", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.integer("scores", min: 0, max: 100).map().field()],
        constructor: (data) => data,
      );

      final validData = {
        "name": "Skills Assessment",
        "scores": {"piloting": 90, "combat": 85},
      };

      final invalidData = {
        "name": "Skills Assessment",
        "scores": {
          "piloting": 90,
          "combat": 150, // exceeds max constraint
        },
      };

      expect(schema.fromJson(validData)["scores"]["piloting"], equals(90));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("processes maps using Schema.map", () {
      final pilotSchema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.integer("skillLevel").field()],
        constructor: (data) => data,
      );

      final pilotsJson = {
        "red_leader": {"name": "Wedge Antilles", "skillLevel": 9},
        "gold_leader": {"name": "Dutch Vander", "skillLevel": 8},
        "black_leader": {"name": "Poe Dameron", "skillLevel": 10},
      };

      final pilots = pilotSchema.map(pilotsJson);

      expect(pilots.length, equals(3));
      expect(pilots["red_leader"]!["name"], equals("Wedge Antilles"));
      expect(pilots["gold_leader"]!["skillLevel"], equals(8));
      expect(pilots["black_leader"]!["name"], equals("Poe Dameron"));
    });

    test("throws JsonTypeException when Schema.map receives non-map input", () {
      final schema = Schema<Map<String, dynamic>>(fields: [Field.string("name").field()], constructor: (data) => data);

      final invalidInput = ["this is", "not a", "map"];

      expect(() => schema.map(invalidInput), throwsA(TypeMatcher<JsonTypeException>()));
    });

    test("handles optional map fields", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.string("aliases").map().optional().field()],
        constructor: (data) => data,
      );

      final dataWithAliases = {
        "name": "Obi-Wan Kenobi",
        "aliases": {"jedi": "Ben Kenobi", "code": "Old Ben"},
      };

      final dataWithoutAliases = {"name": "Obi-Wan Kenobi"};

      final result1 = schema.fromJson(dataWithAliases);
      final result2 = schema.fromJson(dataWithoutAliases);

      expect(result1["aliases"]!["jedi"], equals("Ben Kenobi"));
      expect(result2["aliases"], isNull);
    });

    test("uses fallback for map fields", () {
      final fallbackMap = {"default": "value", "standard": "setting"};

      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("settings").map(fallback: fallbackMap).field()],
        constructor: (data) => data,
      );

      final data = {};

      final result = schema.fromJson(data);
      expect(result["settings"], equals(fallbackMap));
      expect(result["settings"]["default"], equals("value"));
    });
  });
}
