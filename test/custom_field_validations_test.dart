import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, test, throwsA;

void main() {
  group("Custom field validations", () {
    test("applies custom conversion logic", () {
      final schema = Schema(
        fields: [
          Field.string("name"),
          Field.custom<int, String>(
            "code",
            converter: (value) {
              if (!value.startsWith("SW-")) {
                throw ArgumentError("Code must start with SW-");
              }
              return int.parse(value.substring(3));
            },
          ),
        ],
        constructor: (data) => data,
      );

      final validData = {"name": "Luke Skywalker", "code": "SW-123"};
      final invalidData = {"name": "Luke Skywalker", "code": "ABC-123"};

      expect(schema.fromJson(validData)["code"], equals(123));
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });
  });
}
