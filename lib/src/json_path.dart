/// Represents a path to a value in a JSON document using JSONPath notation.
///
/// JsonPath is a string syntax for identifying specific elements within a JSON document. This class provides a way to build and manipulate JSONPath expressions, primarily for tracking and reporting the location of validation errors.
///
/// JsonPath uses:
/// - $ to represent the root document
/// - .property to navigate to a property of an object
/// - [index] to navigate to an element in an array
///
/// Example:
/// ```dart
/// final path = JsonPath.root() / 'users' / 'address' / 'zipCode';
/// print(path); // $.users.address.zipCode
///
/// final arrayPath = ((JsonPath.root() / 'users')[2] / 'roles')[0];
/// print(arrayPath); // $.users[2].roles[0]
/// ```
class JsonPath {
  /// The individual segments of the path.
  ///
  /// Each segment represents one step in the path navigation.
  final List<String> segments;

  /// Creates a JsonPath with the specified segments.
  ///
  /// This constructor is private to ensure paths are always built using the root() constructor and operators.
  const JsonPath._(this.segments);

  /// Creates a root JsonPath that points to the document root.
  ///
  /// This is the starting point for building any path.
  const JsonPath.root() : segments = const ["\$"];

  /// Adds a property segment to the path, creating a new JsonPath instance.
  ///
  /// This operator enables fluent path construction using the / operator.
  ///
  /// Parameters:
  /// - [key]: The property name to add to the path
  ///
  /// Returns a new JsonPath with the added property segment.
  ///
  /// Example:
  /// ```dart
  /// final path = JsonPath.root() / 'user' / 'email';
  /// ```
  JsonPath operator /(String key) => JsonPath._([...segments, ".${_escape(key)}"]);

  /// Adds an array index segment to the path, creating a new JsonPath instance.
  ///
  /// This operator enables fluent path construction for array indices using the [] operator.
  ///
  /// Parameters:
  /// - [index]: The array index to add to the path
  ///
  /// Returns a new JsonPath with the added index segment.
  ///
  /// Example:
  /// ```dart
  /// final path = (JsonPath.root() / 'users')[0] / 'name';
  /// ```
  JsonPath operator [](int index) => JsonPath._([...segments, "[$index]"]);

  /// Converts the path to a string representation in JSONPath format.
  ///
  /// Returns a string representation of the complete path.
  @override
  String toString() => segments.join("");

  /// Escapes special characters in a path segment.
  ///
  /// This ensures that property names with special characters are correctly represented in the JSONPath string.
  ///
  /// Parameters:
  /// - [segment]: The path segment to escape
  ///
  /// Returns the escaped segment string.
  String _escape(String segment) {
    return segment.isEmpty || segment.contains(RegExp(r"[\s\[\]\{\}\.\$]"))
        ? "'${segment.replaceAll("'", "\\'")}'"
        : segment;
  }
}
