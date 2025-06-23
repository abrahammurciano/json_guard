import "package:json_guard/json_guard.dart" show Field, Schema;

class NamingPattern {
  final String name;
  final RegExp regex;

  NamingPattern({required this.name, required this.regex});

  bool isValid(String input) {
    return regex.hasMatch(input);
  }

  // Define a schema for a naming pattern
  static final schema = Schema(
    fields: [
      Field.string("name").field(),
      Field.pattern("regex", full: true, fallback: RegExp(r"[a-zA-Z][a-zA-Z0-9_]*")).field(),
    ],
    constructor: (data) => NamingPattern(name: data["name"], regex: data["regex"]),
  );
}

class ValidationRules {
  final NamingPattern identifierPattern;
  final NamingPattern? variablePattern;

  ValidationRules({required this.identifierPattern, this.variablePattern});

  // Define a schema for validation rules
  static final schema = Schema(
    fields: [
      Field.nested("identifierPattern", schema: NamingPattern.schema).field(),
      Field.nested("variablePattern", schema: NamingPattern.schema).optional().field(),
    ],
    constructor: (data) {
      return ValidationRules(identifierPattern: data["identifierPattern"], variablePattern: data["variablePattern"]);
    },
  );
}

void main() {
  final json = {
    "identifierPattern": {"name": "PascalCase", "regex": "[A-Z][a-z0-9]+(?:[A-Z][a-z0-9]+)*"},
    "variablePattern": {"name": "camelCase", "regex": "[a-z][a-z0-9]+(?:[A-Z][a-z0-9]+)*"},
  };

  final rules = ValidationRules.schema.fromJson(json);

  print("Validation Rules:");
  print("Identifier Pattern: ${rules.identifierPattern.name}");
  print("Identifier Regex: ${rules.identifierPattern.regex.pattern}");
  print("Variable Pattern: ${rules.variablePattern?.name ?? 'None'}");

  // Test matching against the patterns
  final identifierToTest = "UserAccount";
  final variableToTest = "userAccount";

  print("\nTesting patterns:");
  print("'$identifierToTest' matches identifier pattern: ${rules.identifierPattern.regex.hasMatch(identifierToTest)}");
  print("'$variableToTest' matches variable pattern: ${rules.variablePattern!.regex.hasMatch(variableToTest)}");

  // Test invalid regex pattern
  try {
    final invalidJson = {
      "identifierPattern": {"name": "Invalid Pattern", "regex": "[unclosed bracket"},
    };
    ValidationRules.schema.fromJson(invalidJson);
  } catch (e) {
    print("\nExpected validation error:");
    print(e);
  }
}
