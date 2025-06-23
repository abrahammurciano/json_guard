import "package:json_guard/json_guard.dart"
    show
        Field,
        Schema,
        ValueValidationException,
        FieldMissingException,
        ArgumentErrorValidationException,
        JsonTypeException;
import "package:test/test.dart"
    show TypeMatcher, contains, equals, expect, fail, group, isA, isNull, isTrue, isFalse, test, throwsA;

enum TestEnum { light, dark, neutral }

class SimpleTest {
  final String name;
  final int age;

  SimpleTest({required this.name, required this.age});

  @override
  bool operator ==(Object other) => other is SimpleTest && other.name == name && other.age == age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

void main() {
  group("Schema validations", () {
    test("validates basic types", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker", "age": 23};
      final result = schema.fromJson(data);

      expect(result.name, equals("Luke Skywalker"));
      expect(result.age, equals(23));
    });

    test("throws on missing fields", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker"};

      expect(() => schema.fromJson(data), throwsA(TypeMatcher<FieldMissingException>()));
    });

    test("uses field fallbacks", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age", fallback: 20).field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker"};
      final result = schema.fromJson(data);

      expect(result.name, equals("Luke Skywalker"));
      expect(result.age, equals(20));
    });

    test("uses field aliases", () {
      final schema = Schema<SimpleTest>(
        fields: [
          Field.string("name", aliases: ["fullName", "characterName"]).field(),
          Field.integer("age", aliases: ["years"]).field(),
        ],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final data = {"characterName": "Luke Skywalker", "years": 23};
      final result = schema.fromJson(data);

      expect(result.name, equals("Luke Skywalker"));
      expect(result.age, equals(23));
    });

    test("catches ArgumentError in constructor and throws ArgumentErrorValidationException", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) {
          final age = data["age"] as int;
          if (age < 0) {
            throw ArgumentError("Age cannot be negative");
          }
          return SimpleTest(name: data["name"], age: age);
        },
      );

      final validData = {"name": "Luke Skywalker", "age": 23};
      final invalidData = {"name": "Luke Skywalker", "age": -5};

      expect(schema.fromJson(validData).age, equals(23));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ArgumentErrorValidationException>()));
    });
  });

  group("Integer field validations", () {
    test("enforces min constraint", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age", min: 18).field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke Skywalker", "age": 23};
      final invalidData = {"name": "Grogu", "age": 5};

      expect(schema.fromJson(validData).age, equals(23));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("enforces max constraint", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age", max: 100).field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke Skywalker", "age": 23};
      final invalidData = {"name": "Yoda", "age": 900};

      expect(schema.fromJson(validData).age, equals(23));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("supports string-to-integer conversion", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final data = {"name": "Luke Skywalker", "age": "23"};
      expect(schema.fromJson(data).age, equals(23));
    });

    test("rejects invalid integers", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final invalidData = {"name": "Luke Skywalker", "age": "twenty-three"};
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });
  });

  group("String field validations", () {
    test("enforces minLength constraint", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name", minLength: 3).field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "R2", "age": 30};

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("enforces maxLength constraint", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name", maxLength: 10).field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "Luke Skywalker of Tatooine", "age": 23};

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("applies trim option", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name", trim: true).field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final data = {"name": "  Luke Skywalker  ", "age": 23};
      expect(schema.fromJson(data).name, equals("Luke Skywalker"));
    });

    test("validates pattern constraint", () {
      final schema = Schema<SimpleTest>(
        fields: [
          Field.string("name", pattern: RegExp(r"^[A-Z][a-z]+$")).field(),
          Field.integer("age").field(),
        ],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "luke", "age": 23}; // lowercase first letter

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("validates options constraint", () {
      final schema = Schema<SimpleTest>(
        fields: [
          Field.string("name", options: {"Luke", "Leia", "Han"}).field(),
          Field.integer("age").field(),
        ],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final validData = {"name": "Luke", "age": 23};
      final invalidData = {"name": "Darth Vader", "age": 45};

      expect(schema.fromJson(validData).name, equals("Luke"));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });
  });

  group("DateTime field validations", () {
    test("parses ISO8601 strings", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.datetime("date").field()],
        constructor: (data) => data,
      );

      final data = {"date": "2023-05-04T12:00:00Z"};
      final expected = DateTime.parse("2023-05-04T12:00:00Z");

      final result = schema.fromJson(data);
      expect(result["date"], equals(expected));
    });

    test("parses timestamps", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.datetime("date").field()],
        constructor: (data) => data,
      );

      final timestamp = 1683201600; // 2023-05-04T12:00:00Z
      final data = {"date": timestamp};
      final expected = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      final result = schema.fromJson(data);
      expect(result["date"], equals(expected));
    });

    test("enforces min constraint", () {
      final minDate = DateTime(2023, 1, 1);
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.datetime("date", min: minDate).field()],
        constructor: (data) => data,
      );

      final validData = {"date": "2023-05-04T12:00:00Z"};
      final invalidData = {"date": "2022-05-04T12:00:00Z"};

      expect(schema.fromJson(validData)["date"], isA<DateTime>());
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("enforces max constraint", () {
      final maxDate = DateTime(2023, 12, 31);
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.datetime("date", max: maxDate).field()],
        constructor: (data) => data,
      );

      final validData = {"date": "2023-05-04T12:00:00Z"};
      final invalidData = {"date": "2024-05-04T12:00:00Z"};

      expect(schema.fromJson(validData)["date"], isA<DateTime>());
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });
  });

  group("Enum field validations", () {
    test("maps string values to enum values", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.enumeration<TestEnum>(
            "side",
            values: {"light": TestEnum.light, "dark": TestEnum.dark, "neutral": TestEnum.neutral},
          ).field(),
        ],
        constructor: (data) => data,
      );

      final data = {"side": "light"};

      final result = schema.fromJson(data);
      expect(result["side"], equals(TestEnum.light));
    });

    test("handles case sensitivity", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.enumeration<TestEnum>(
            "side",
            values: {"light": TestEnum.light, "dark": TestEnum.dark},
            caseSensitive: true,
          ).field(),
        ],
        constructor: (data) => data,
      );

      final validData = {"side": "light"};
      final invalidData = {"side": "LIGHT"};

      expect(schema.fromJson(validData)["side"], equals(TestEnum.light));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("handles case insensitivity", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.enumeration<TestEnum>(
            "side",
            values: {"light": TestEnum.light, "dark": TestEnum.dark},
            caseSensitive: false,
          ).field(),
        ],
        constructor: (data) => data,
      );

      final validData1 = {"side": "light"};
      final validData2 = {"side": "LIGHT"};
      final validData3 = {"side": "Light"};

      expect(schema.fromJson(validData1)["side"], equals(TestEnum.light));
      expect(schema.fromJson(validData2)["side"], equals(TestEnum.light));
      expect(schema.fromJson(validData3)["side"], equals(TestEnum.light));
    });

    test("validates enum values", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.enumeration<TestEnum>("side", values: {"light": TestEnum.light, "dark": TestEnum.dark}).field(),
        ],
        constructor: (data) => data,
      );

      final validData = {"side": "light"};
      final invalidData = {"side": "unknown"};

      expect(schema.fromJson(validData)["side"], equals(TestEnum.light));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });
  });

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

  group("List field validations", () {
    test("validates lists of primitives", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.string("powers").list().field()],
        constructor: (data) => data,
      );

      final data = {
        "name": "Luke Skywalker",
        "powers": ["telekinesis", "mind trick", "lightsaber combat"],
      };

      final result = schema.fromJson(data);
      expect(result["name"], equals("Luke Skywalker"));
      expect(result["powers"], equals(["telekinesis", "mind trick", "lightsaber combat"]));
    });

    test("validates lists of complex objects", () {
      final weaponSchema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.integer("damage").field()],
        constructor: (data) => data,
      );

      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.string("name").field(),
          Field.nested("weapons", schema: weaponSchema).list().field(),
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
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.integer("scores").list().field()],
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
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });
  });

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

  group("Custom field validations", () {
    test("applies custom conversion logic", () {
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

      final validData = {"name": "Luke Skywalker", "code": "SW-123"};
      final invalidData = {"name": "Luke Skywalker", "code": "ABC-123"};

      expect(schema.fromJson(validData)["code"], equals(123));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ArgumentErrorValidationException>()));
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
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) {
          final age = data["age"] as int;
          if (age < 0) {
            throw ArgumentError("Age cannot be negative");
          }
          return SimpleTest(name: data["name"], age: age);
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

  group("Schema.list tests", () {
    test("validates a list of JSON objects", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Leia Organa", "age": 23},
        {"name": "Han Solo", "age": 32},
      ];

      final results = schema.list(jsonList);

      expect(results.length, equals(3));
      expect(results[0].name, equals("Luke Skywalker"));
      expect(results[0].age, equals(23));
      expect(results[1].name, equals("Leia Organa"));
      expect(results[1].age, equals(23));
      expect(results[2].name, equals("Han Solo"));
      expect(results[2].age, equals(32));
    });

    test("throws JsonTypeException with correct path when list item is not a map", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        "not a map",
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown JsonTypeException");
      } on JsonTypeException catch (e) {
        expect(e.data, equals("not a map"));
        expect(e.path.toString(), equals("\$[1]"));
      }
    });

    test("throws FieldMissingException with correct path when field is missing", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Leia Organa"}, // missing age
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown FieldMissingException");
      } on FieldMissingException catch (e) {
        expect(e.field?.name, equals("age"));
        expect(e.path.toString(), equals("\$[1].age"));
      }
    });

    test("throws ValueValidationException with correct path on validation failure", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age", min: 18).field()],
        constructor: (data) => SimpleTest(name: data["name"], age: data["age"]),
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Grogu", "age": 5}, // too young
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ValueValidationException");
      } on ValueValidationException catch (e) {
        expect(e.value, equals(5));
        expect(e.field?.name, equals("age"));
        expect(e.path.toString(), equals("\$[1].age"));
        expect(e.reason, contains("at least"));
      }
    });

    test("throws ArgumentErrorValidationException with correct path on converter error", () {
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

      final jsonList = [
        {"name": "Luke Skywalker", "code": "SW-123"},
        {"name": "Darth Vader", "code": "DV-456"}, // invalid prefix
        {"name": "Han Solo", "code": "SW-789"},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ArgumentErrorValidationException catch (e) {
        expect(e.value, equals("DV-456"));
        expect(e.field?.name, equals("code"));
        expect(e.path.toString(), equals("\$[1].code"));
        expect(e.reason, equals("Code must start with SW-"));
      }
    });

    test("throws ArgumentErrorValidationException with correct path on schema constructor error", () {
      final schema = Schema<SimpleTest>(
        fields: [Field.string("name").field(), Field.integer("age").field()],
        constructor: (data) {
          final age = data["age"] as int;
          if (age < 0) {
            throw ArgumentError("Age cannot be negative");
          }
          return SimpleTest(name: data["name"], age: age);
        },
      );

      final jsonList = [
        {"name": "Luke Skywalker", "age": 23},
        {"name": "Clone", "age": -5}, // negative age
        {"name": "Han Solo", "age": 32},
      ];

      try {
        schema.list(jsonList);
        fail("Should have thrown ArgumentErrorValidationException");
      } on ArgumentErrorValidationException catch (e) {
        expect(e.value, equals({"name": "Clone", "age": -5}));
        expect(e.path.toString(), equals("\$[1]"));
        expect(e.reason, equals("Age cannot be negative"));
      }
    });
  });

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

  group("Pattern field validations", () {
    test("converts string to RegExp", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name").field(), Field.pattern("idPattern").field()],
        constructor: (data) => data,
      );

      final data = {"name": "ID Validation Rule", "idPattern": "[A-Z]{2}\\d{6}"};

      final result = schema.fromJson(data);
      expect(result["name"], equals("ID Validation Rule"));
      expect(result["idPattern"], isA<RegExp>());
      expect(result["idPattern"].pattern, equals("[A-Z]{2}\\d{6}"));

      // Test the resulting RegExp
      expect(result["idPattern"].hasMatch("AB123456"), isTrue);
      expect(result["idPattern"].hasMatch("12AB3456"), isFalse);
    });

    test("supports 'full' flag to anchor patterns", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.pattern("pattern", full: true).field()],
        constructor: (data) => data,
      );

      final data = {"pattern": "[a-z]+"};

      final result = schema.fromJson(data);
      expect(result["pattern"].pattern, equals("^[a-z]+\$"));

      // Should match full string only
      expect(result["pattern"].hasMatch("abc"), isTrue);
      expect(result["pattern"].hasMatch("abc123"), isFalse);
      expect(result["pattern"].hasMatch("123abc"), isFalse);
    });

    test("recognizes existing anchors when full flag is true", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [
          Field.pattern("startPattern", full: true).field(),
          Field.pattern("endPattern", full: true).field(),
          Field.pattern("fullPattern", full: true).field(),
        ],
        constructor: (data) => data,
      );

      final data = {"startPattern": "^[a-z]+", "endPattern": "[0-9]+\$", "fullPattern": "^[A-Z]+\$"};

      final result = schema.fromJson(data);

      // Should not duplicate anchors
      expect(result["startPattern"].pattern, equals("^[a-z]+\$"));
      expect(result["endPattern"].pattern, equals("^[0-9]+\$"));
      expect(result["fullPattern"].pattern, equals("^[A-Z]+\$"));
    });

    test("configures RegExp options", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.pattern("pattern", multiLine: true, caseSensitive: false, unicode: true).field()],
        constructor: (data) => data,
      );

      final data = {"pattern": "test"};

      final result = schema.fromJson(data);
      final pattern = result["pattern"];

      expect(pattern.isMultiLine, isTrue);
      expect(pattern.isCaseSensitive, isFalse);
      expect(pattern.isUnicode, isTrue);

      // Test case insensitivity
      expect(pattern.hasMatch("TEST"), isTrue);
    });

    test("uses fallback when field is missing", () {
      final fallbackPattern = RegExp(r"[a-z][A-Z]+");
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.pattern("pattern", fallback: fallbackPattern).field()],
        constructor: (data) => data,
      );

      final data = {};

      final result = schema.fromJson(data);
      expect(result["pattern"], equals(fallbackPattern));

      // Test the resulting RegExp is the fallback
      expect(result["pattern"].hasMatch("aBC"), isTrue);
      expect(result["pattern"].hasMatch("ABC"), isFalse);
    });

    test("throws ValueValidationException on invalid pattern", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.pattern("pattern").field()],
        constructor: (data) => data,
      );

      final invalidData = {"pattern": "["}; // Unclosed bracket - invalid regex

      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValueValidationException>()));
    });

    test("provides error message on invalid pattern", () {
      final schema = Schema<Map<String, dynamic>>(
        fields: [Field.pattern("pattern").field()],
        constructor: (data) => data,
      );

      final invalidData = {"pattern": "["}; // Unclosed bracket - invalid regex

      try {
        schema.fromJson(invalidData);
        fail("Expected ValueValidationException was not thrown");
      } catch (e) {
        expect(e, isA<ValueValidationException>());
        expect((e as ValueValidationException).message, contains("Invalid regular expression"));
      }
    });
  });
}
