import "package:json_guard/json_guard.dart" show Field, Schema, ValidationException;
import "package:test/test.dart" show TypeMatcher, equals, expect, group, isA, test, throwsA;

void main() {
  group("DateTime field validations", () {
    test("parses ISO8601 strings", () {
      final schema = Schema(fields: [Field.datetime("date")], constructor: (data) => data);

      final data = {"date": "2023-05-04T12:00:00Z"};
      final expected = DateTime.parse("2023-05-04T12:00:00Z");

      final result = schema.fromJson(data);
      expect(result["date"], equals(expected));
    });

    test("parses timestamps", () {
      final schema = Schema(fields: [Field.datetime("date")], constructor: (data) => data);

      final timestamp = 1683201600; // 2023-05-04T12:00:00Z
      final data = {"date": timestamp};
      final expected = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      final result = schema.fromJson(data);
      expect(result["date"], equals(expected));
    });

    test("enforces min constraint", () {
      final minDate = DateTime(2023, 1, 1);
      final schema = Schema(
        fields: [Field.datetime("date", min: minDate)],
        constructor: (data) => data,
      );

      final validData = {"date": "2023-05-04T12:00:00Z"};
      final invalidData = {"date": "2022-05-04T12:00:00Z"};

      expect(schema.fromJson(validData)["date"], isA<DateTime>());
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });

    test("enforces max constraint", () {
      final maxDate = DateTime(2023, 12, 31);
      final schema = Schema(
        fields: [Field.datetime("date", max: maxDate)],
        constructor: (data) => data,
      );

      final validData = {"date": "2023-05-04T12:00:00Z"};
      final invalidData = {"date": "2024-05-04T12:00:00Z"};

      expect(schema.fromJson(validData)["date"], isA<DateTime>());
      expect(() => schema.fromJson(invalidData), throwsA(TypeMatcher<ValidationException>()));
    });
  });
}
