/// Represents a path to a value in a JSON document.
///
/// JsonPath uses a dot notation similar to JavaScript property access to identify
/// locations within a JSON structure. It provides a way to track and report the location
/// of validation errors.
class JsonPath {
  /// The individual segments of the path.
  final List<String> segments;

  /// Creates a JsonPath with the specified segments.
  const JsonPath._(this.segments);

  /// Creates a root JsonPath that points to the document root.
  const JsonPath.root() : segments = const ["\$"];

  /// Adds a segment to the path, creating a new JsonPath instance.
  ///
  /// This operator enables fluent path construction using the / operator.
  JsonPath operator /(String key) => JsonPath._([...segments, ".${_escape(key)}"]);

  /// Adds an index segment to the path, creating a new JsonPath instance.
  ///
  /// This operator enables fluent path construction for array indices using the [] operator.
  JsonPath operator [](int index) => JsonPath._([...segments, "[$index]"]);

  /// Converts the path to a string representation in JSONPath format.
  @override
  String toString() => segments.join("");

  /// Escapes special characters in a path segment.
  String _escape(String segment) {
    return segment.isEmpty || segment.contains(RegExp(r"[\s\[\]\{\}\.\$]"))
        ? "'${segment.replaceAll("'", "\\'")}'"
        : segment;
  }
}
