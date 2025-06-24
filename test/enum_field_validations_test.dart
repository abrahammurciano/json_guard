import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, test, throwsA;

import "test_utils.dart" show TestEnum;

void main() {
  group("Enum field validations", () {
    test("maps string values to enum values", () {
      final schema = Schema(
        fields: [
          Field.enumeration(
            "side",
            values: {"light": TestEnum.light, "dark": TestEnum.dark, "neutral": TestEnum.neutral},
          ),
        ],
        constructor: (data) => data,
      );

      final data = {"side": "light"};

      final result = schema.fromJson(data);
      expect(result["side"], equals(TestEnum.light));
    });

    test("handles case sensitivity", () {
      final schema = Schema(
        fields: [
          Field.enumeration("side", values: {"light": TestEnum.light, "dark": TestEnum.dark}, caseSensitive: true),
        ],
        constructor: (data) => data,
      );

      final validData = {"side": "light"};
      final invalidData = {"side": "LIGHT"};

      expect(schema.fromJson(validData)["side"], equals(TestEnum.light));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });

    test("handles case insensitivity", () {
      final schema = Schema(
        fields: [
          Field.enumeration("side", values: {"light": TestEnum.light, "dark": TestEnum.dark}, caseSensitive: false),
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
      final schema = Schema(
        fields: [
          Field.enumeration("side", values: {"light": TestEnum.light, "dark": TestEnum.dark}),
        ],
        constructor: (data) => data,
      );

      final validData = {"side": "light"};
      final invalidData = {"side": "unknown"};

      expect(schema.fromJson(validData)["side"], equals(TestEnum.light));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });
  });
}
