import "package:json_guard/src/exceptions.dart" show ValidationException;
import "package:json_guard/src/field.dart" show Field;
import "package:json_guard/src/schema.dart" show Schema;
import "package:json_guard/src/validator.dart" show Validator;
import "package:json_guard/src/validators/string_validator.dart" show StringCase;
import "package:test/test.dart" show equals, expect, group, isA, isNull, isTrue, test, throwsA;

enum TestEnum { light, dark, neutral }

void main() {
  group("Validator.validate", () {
    test("validates a simple value", () {
      final validator = Validator.integer();

      expect(validator.validate("42"), equals(42));
      expect(() => validator.validate("not a number"), throwsA(isA<ValidationException>()));
    });

    test("handles null values", () {
      final requiredValidator = Validator.integer();
      final optionalValidator = Validator.integer().optional();

      expect(() => requiredValidator.validate(null), throwsA(isA<ValidationException>()));
      expect(optionalValidator.validate(null), isNull);
    });

    test("uses fallback when value is missing", () {
      final validator = Validator.integer(fallback: 42);

      expect(validator.validate(null), equals(42));
    });

    test("uses fallbackBuilder when value is missing", () {
      int counter = 0;
      final validator = Validator.custom(
        converter: (value, _) => int.parse(value.toString()),
        fallbackBuilder: () => counter++,
      );

      expect(validator.validate(null), equals(0));
      expect(validator.validate(null), equals(1));
    });
  });

  group("Validator.optional", () {
    test("creates an optional validator", () {
      final validator = Validator.integer().optional();

      expect(validator.validate("42"), equals(42));
      expect(validator.validate(null), isNull);
    });

    test("preserves null in optional validator", () {
      final validator = Validator.integer(fallback: 42).optional();
      expect(validator.validate(null), isNull);
    });

    test("preserves fallback in required validator", () {
      final validator = Validator.integer(fallback: 42);
      expect(validator.validate(null), equals(42));
    });
  });

  group("Validator.list", () {
    test("validates each item in a list", () {
      final validator = Validator.integer().list();
      expect(validator.validate(["1", "2", "3"]), equals([1, 2, 3]));
      expect(() => validator.validate(["1", "not a number", "3"]), throwsA(isA<ValidationException>()));
    });

    test("handles empty lists", () {
      final validator = Validator.integer().list();
      expect(validator.validate([]), equals([]));
    });

    test("uses fallback when list is missing", () {
      final validator = Validator.integer().list(fallback: [42, 43]);
      expect(validator.validate(null), equals([42, 43]));
    });
  });

  group("Validator.map", () {
    test("validates each value in a map", () {
      final validator = Validator.integer().map();
      expect(validator.validate({"a": "1", "b": "2", "c": "3"}), equals({"a": 1, "b": 2, "c": 3}));
      expect(() => validator.validate({"a": "1", "b": "not a number", "c": "3"}), throwsA(isA<ValidationException>()));
    });

    test("handles empty maps", () {
      final validator = Validator.integer().map();
      expect(validator.validate({}), equals({}));
    });

    test("uses fallback when map is missing", () {
      final validator = Validator.integer().map(fallback: {"a": 42, "b": 43});
      expect(validator.validate(null), equals({"a": 42, "b": 43}));
    });
  });

  group("Validator.plain", () {
    test("creates a validator without conversion", () {
      final validator = Validator<int>.plain(fallback: 42);

      expect(validator.validate(5), equals(5));
      expect(validator.validate(null), equals(42));
      expect(() => validator.validate("not an int"), throwsA(isA<ValidationException>()));
    });
  });

  group("Validator.custom", () {
    test("creates a validator with custom conversion", () {
      final validator = Validator.custom<double, String>(
        converter: (value, path) => double.parse(value),
        fallback: 3.14,
      );

      expect(validator.validate("2.5"), equals(2.5));
      expect(validator.validate(null), equals(3.14));
      expect(() => validator.validate("not a double"), throwsA(isA<ValidationException>()));
    });
  });

  group("Validator.integer", () {
    test("creates an integer validator", () {
      final validator = Validator.integer(min: 1, max: 100, fallback: 50);

      expect(validator.validate(42), equals(42));
      expect(validator.validate(null), equals(50));
      expect(() => validator.validate(101), throwsA(isA<ValidationException>()));
      expect(() => validator.validate(0), throwsA(isA<ValidationException>()));
      expect(() => validator.validate("not an int"), throwsA(isA<ValidationException>()));
    });
  });

  group("Validator.string", () {
    test("creates a string validator with constraints", () {
      final validator = Validator.string(minLength: 3, maxLength: 10, trim: true, fallback: "default");

      expect(validator.validate("hello"), equals("hello"));
      expect(validator.validate("  trimmed  "), equals("trimmed"));
      expect(validator.validate(null), equals("default"));
      expect(() => validator.validate("hi"), throwsA(isA<ValidationException>()));
      expect(() => validator.validate("this is too long"), throwsA(isA<ValidationException>()));
    });

    test("string validator with pattern", () {
      final validator = Validator.string(pattern: RegExp(r"^[A-Z][a-z]+$"), fallback: "Name");

      expect(validator.validate("Name"), equals("Name"));
      expect(() => validator.validate("name"), throwsA(isA<ValidationException>()));
      expect(() => validator.validate("NAME"), throwsA(isA<ValidationException>()));
    });

    test("string validator with case transformation", () {
      final lowercaseValidator = Validator.string(caseType: StringCase.lower);
      final uppercaseValidator = Validator.string(caseType: StringCase.upper);

      expect(lowercaseValidator.validate("MiXeD"), equals("mixed"));
      expect(uppercaseValidator.validate("MiXeD"), equals("MIXED"));
    });

    test("string validator with options", () {
      final validator = Validator.string(options: {"red", "green", "blue"});

      expect(validator.validate("red"), equals("red"));
      expect(() => validator.validate("yellow"), throwsA(isA<ValidationException>()));
    });
  });

  group("Validator.datetime", () {
    test("creates a datetime validator", () {
      final min = DateTime(2000);
      final max = DateTime(2030);
      final fallback = DateTime(2023);

      final validator = Validator.datetime(min: min, max: max, fallback: fallback);

      expect(validator.validate("2020-01-01"), DateTime(2020, 1, 1));
      expect(validator.validate(1577836800).toUtc(), DateTime(2020, 1, 1).copyWith(isUtc: true));
      expect(validator.validate(null), equals(fallback));
      expect(() => validator.validate("1999-12-31"), throwsA(isA<ValidationException>()));
      expect(() => validator.validate("2031-01-01"), throwsA(isA<ValidationException>()));
    });

    test("datetime validator with ISO8601 disabled", () {
      final validator = Validator.datetime(allowIso8601: false);

      expect(() => validator.validate("2020-01-01"), throwsA(isA<ValidationException>()));
      expect(validator.validate(1577836800).toUtc(), DateTime(2020, 1, 1).copyWith(isUtc: true));
    });

    test("datetime validator with timestamp disabled", () {
      final validator = Validator.datetime(allowTimestamp: false);

      expect(validator.validate("2020-01-01"), DateTime(2020, 1, 1));
      expect(() => validator.validate(1577836800000), throwsA(isA<ValidationException>()));
    });
  });

  group("Validator.enumeration", () {
    test("creates an enum validator", () {
      final validator = Validator.enumeration<TestEnum>(
        values: {"light": TestEnum.light, "dark": TestEnum.dark, "neutral": TestEnum.neutral},
        fallback: TestEnum.neutral,
      );

      expect(validator.validate("light"), equals(TestEnum.light));
      expect(validator.validate(null), equals(TestEnum.neutral));
      expect(() => validator.validate("unknown"), throwsA(isA<ValidationException>()));
    });

    test("enum validator with case insensitivity", () {
      final validator = Validator.enumeration<TestEnum>(
        values: {"light": TestEnum.light, "dark": TestEnum.dark, "neutral": TestEnum.neutral},
        caseSensitive: false,
      );

      expect(validator.validate("LIGHT"), equals(TestEnum.light));
      expect(validator.validate("Dark"), equals(TestEnum.dark));
    });
  });

  group("Validator.pattern", () {
    test("creates a pattern validator", () {
      final validator = Validator.pattern(full: true, caseSensitive: false);

      final regExp = validator.validate("abc");
      expect(regExp.pattern, equals("^abc\$"));
      expect(regExp.isCaseSensitive, equals(false));
    });

    test("pattern validator with multiLine", () {
      final validator = Validator.pattern(multiLine: true);

      final regExp = validator.validate("^abc");
      expect(regExp.isMultiLine, isTrue);
    });

    test("pattern validator for invalid patterns", () {
      final validator = Validator.pattern();

      expect(() => validator.validate("[unclosed"), throwsA(isA<ValidationException>()));
    });
  });

  group("Chained Validators", () {
    test("applies nested validation", () {
      final validator = Validator.integer(min: 0).list().optional();

      expect(validator.validate([1, "2", 3]), equals([1, 2, 3]));
      expect(validator.validate(null), isNull);
      expect(() => validator.validate([-1, 0, 1]), throwsA(isA<ValidationException>()));
    });

    test("optional list of strings", () {
      final validator = Validator.string(minLength: 3, coerce: true).list().optional();

      expect(validator.validate(["hello", "world", 1234]), equals(["hello", "world", "1234"]));
      expect(validator.validate(null), isNull);
      expect(() => validator.validate(["hi"]), throwsA(isA<ValidationException>()));
    });
  });

  group("Validator.schema", () {
    test("creates a validator for a nested schema", () {
      // Create a simple Person schema
      final personSchema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name", minLength: 2), Field.integer("age", min: 0)],
        constructor: (data) => data,
      );

      final validator = Validator.schema(schema: personSchema);

      // Valid person
      final validPerson = {"name": "Alice", "age": 30};
      expect(validator.validate(validPerson), equals(validPerson));

      // Invalid name (too short)
      final invalidName = {"name": "A", "age": 30};
      expect(() => validator.validate(invalidName), throwsA(isA<ValidationException>()));

      // Invalid age (negative)
      final invalidAge = {"name": "Bob", "age": -5};
      expect(() => validator.validate(invalidAge), throwsA(isA<ValidationException>()));
    });

    test("uses fallback when schema input is missing", () {
      final personSchema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => data,
      );

      final fallbackPerson = {"name": "Default", "age": 25};
      final validator = Validator.schema(schema: personSchema, fallback: fallbackPerson);

      expect(validator.validate(null), equals(fallbackPerson));
    });

    test("validates nested schema in a list", () {
      final personSchema = Schema<Map<String, dynamic>>(
        fields: [Field.string("name"), Field.integer("age")],
        constructor: (data) => data,
      );

      final peopleValidator = Validator.schema(schema: personSchema).list();

      final validPeople = [
        {"name": "Alice", "age": 30},
        {"name": "Bob", "age": 25},
      ];

      expect(peopleValidator.validate(validPeople), equals(validPeople));

      final invalidPeople = [
        {"name": "Alice", "age": 30},
        {"name": "Bob", "age": "not a number"},
      ];

      expect(() => peopleValidator.validate(invalidPeople), throwsA(isA<ValidationException>()));
    });
  });
}
