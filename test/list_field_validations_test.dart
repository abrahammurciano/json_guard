import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, test, throwsA;

void main() {
  group("List field validations", () {
    test("validates lists of primitives", () {
      final schema = Schema(fields: [Field.string("name"), Field.string("powers").list()], constructor: (data) => data);

      final data = {
        "name": "Luke Skywalker",
        "powers": ["telekinesis", "mind trick", "lightsaber combat"],
      };

      final result = schema.fromJson(data);
      expect(result["name"], equals("Luke Skywalker"));
      expect(result["powers"], equals(["telekinesis", "mind trick", "lightsaber combat"]));
    });

    test("validates lists of complex objects", () {
      final weaponSchema = Schema(fields: [Field.string("name"), Field.integer("damage")], constructor: (data) => data);

      final schema = Schema(
        fields: [
          Field.string("name"),
          Field.nested("weapons", schema: weaponSchema).list(),
        ],
        constructor: (data) => data,
      );

      final data = {
        "name": "Millennium Falcon",
        "weapons": [
          {"name": "Quad laser cannon", "damage": 10},
          {"name": "Concussion missiles", "damage": 15},
        ],
      };

      final result = schema.fromJson(data);
      expect(result["name"], equals("Millennium Falcon"));
      expect(result["weapons"].length, equals(2));
      expect(result["weapons"][0]["name"], equals("Quad laser cannon"));
      expect(result["weapons"][1]["damage"], equals(15));
    });

    test("validates list item constraints", () {
      final schema = Schema(
        fields: [Field.string("name"), Field.integer("scores").list()],
        constructor: (data) => data,
      );

      final validData = {
        "name": "Luke Skywalker",
        "scores": [10, 20, 30],
      };

      final invalidData = {
        "name": "Luke Skywalker",
        "scores": [10, "twenty", 30], // not all integers
      };

      expect(schema.fromJson(validData)["scores"], equals([10, 20, 30]));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });
  });
}
