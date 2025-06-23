import "package:json_guard/json_guard.dart" show Field, Schema, ValueValidationException;
import "package:test/test.dart"
    show TypeMatcher, contains, equals, expect, fail, group, isA, isTrue, isFalse, test, throwsA;

void main() {
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
