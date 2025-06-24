import "package:json_guard/json_guard.dart" show Field, Schema;
import "package:test/test.dart" show equals, expect, group, test;

import "test_utils.dart" show TestModel;

void main() {
  group("Empty dynamic collections", () {
    group("Schema.fromJson with empty dynamic map", () {
      test("accepts empty dynamic map for fromJson", () {
        final schema = Schema(
          fields: [Field.string("name").optional(), Field.integer("age").optional()],
          constructor: (data) => data,
        );

        final Map<dynamic, dynamic> emptyDynamicMap = <dynamic, dynamic>{};
        final result = schema.fromJson(emptyDynamicMap);

        expect(result, equals({"name": null, "age": null}));
      });
    });

    group("Schema.list with empty dynamic list", () {
      test("accepts empty dynamic list for list", () {
        final schema = Schema(
          fields: [Field.string("name"), Field.integer("age")],
          constructor: (data) => TestModel(name: data["name"], age: data["age"]),
        );

        final List<dynamic> emptyDynamicList = <dynamic>[];
        final result = schema.list(emptyDynamicList);

        expect(result, equals([]));
      });
    });

    group("Schema.map with empty dynamic map", () {
      test("accepts empty dynamic map for map", () {
        final schema = Schema(
          fields: [Field.string("name"), Field.integer("age")],
          constructor: (data) => TestModel(name: data["name"], age: data["age"]),
        );

        final Map<dynamic, dynamic> emptyDynamicMap = <dynamic, dynamic>{};
        final result = schema.map(emptyDynamicMap);

        expect(result, equals({}));
      });
    });

    group("Field list type with empty dynamic list", () {
      test("accepts empty dynamic list for list field", () {
        final schema = Schema(
          fields: [Field.string("name"), Field.string("powers").list()],
          constructor: (data) => data,
        );

        final data = {"name": "Luke Skywalker", "powers": <dynamic>[]};

        final result = schema.fromJson(data);
        expect(result["name"], equals("Luke Skywalker"));
        expect(result["powers"], equals([]));
      });
    });

    group("Field map type with empty dynamic map", () {
      test("accepts empty dynamic map for map field", () {
        final schema = Schema(
          fields: [Field.string("name"), Field.integer("scores").map()],
          constructor: (data) => data,
        );

        final data = {"name": "Skills Assessment", "scores": <dynamic, dynamic>{}};

        final result = schema.fromJson(data);
        expect(result["name"], equals("Skills Assessment"));
        expect(result["scores"], equals({}));
      });
    });

    group("Nested schemas with empty dynamic collections", () {
      test("accepts nested empty dynamic map in list", () {
        final characterSchema = Schema(
          fields: [Field.string("name").optional(), Field.integer("age").optional()],
          constructor: (data) => data,
        );

        final schema = Schema(
          fields: [
            Field.string("faction"),
            Field.nested("members", schema: characterSchema).list(),
          ],
          constructor: (data) => data,
        );

        final data = {
          "faction": "Rebellion",
          "members": [<dynamic, dynamic>{}],
        };

        final result = schema.fromJson(data);
        expect(result["faction"], equals("Rebellion"));
        expect(
          result["members"],
          equals([
            {"name": null, "age": null},
          ]),
        );
      });

      test("accepts nested empty dynamic list in map", () {
        final weaponsSchema = Schema(
          fields: [Field.string("name"), Field.string("type").list()],
          constructor: (data) => data,
        );

        final schema = Schema(
          fields: [
            Field.string("name"),
            Field.nested("arsenal", schema: weaponsSchema).map(),
          ],
          constructor: (data) => data,
        );

        final data = {
          "name": "Armory",
          "arsenal": {
            "blasters": {"name": "Blaster Collection", "type": <dynamic>[]},
          },
        };

        final result = schema.fromJson(data);
        expect(result["name"], equals("Armory"));
        expect(result["arsenal"]["blasters"]["name"], equals("Blaster Collection"));
        expect(result["arsenal"]["blasters"]["type"], equals([]));
      });
    });
  });
}
