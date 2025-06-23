import "../exceptions.dart" show ValueValidationException;
import "../field_info.dart" show FieldInfo;
import "../json_path.dart" show JsonPath;

class PatternValidator {
  final bool full;
  final bool multiLine;
  final bool caseSensitive;
  final bool unicode;

  PatternValidator({this.full = false, this.multiLine = false, this.caseSensitive = true, this.unicode = false});

  RegExp validate(String value, JsonPath path, FieldInfo field) {
    try {
      return RegExp(_withAnchors(value), multiLine: multiLine, caseSensitive: caseSensitive, unicode: unicode);
    } catch (e) {
      throw ValueValidationException(value, "Invalid regular expression: $e", field: field, path: path);
    }
  }

  String _withAnchors(String pattern) {
    if (!full) {
      return pattern;
    }
    if (!pattern.startsWith("^")) {
      pattern = "^$pattern";
    }
    if (!pattern.endsWith("\$")) {
      pattern = "$pattern\$";
    }
    return pattern;
  }
}
