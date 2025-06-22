import "../exceptions.dart" show ValueValidationException;
import "../field_info.dart" show FieldInfo;
import "../json_path.dart" show JsonPath;

/// Validator for validating lists and their elements from JSON.
///
/// Validates that a list has the required length and that each element
/// passes validation according to the element field definition.
class ListValidator<T> {
  /// The field definition used to validate each element in the list.
  final FieldInfo<T, dynamic> elements;

  /// The minimum allowed length of the list, if any.
  final int? minLength;

  /// The maximum allowed length of the list, if any.
  final int? maxLength;

  /// Creates a list validator with the specified constraints.
  ListValidator({required this.elements, this.minLength, this.maxLength});

  /// Validates a list and its elements.
  ///
  /// Throws a [ValueValidationException] if the list or any of its elements
  /// don't meet the constraints.
  List<T> validate(List value, JsonPath path, FieldInfo field) {
    return _validateConstraints(_validateElements(value, path, field), path, field);
  }

  /// Checks that the list meets the length constraints.
  List<T> _validateConstraints(List<T> list, JsonPath path, FieldInfo field) {
    if (minLength != null && list.length < minLength!) {
      throw ValueValidationException(list, "List must contain at least $minLength items", field: field, path: path);
    }

    if (maxLength != null && list.length > maxLength!) {
      throw ValueValidationException(list, "List must contain at most $maxLength items", field: field, path: path);
    }

    return list;
  }

  /// Validates each element in the list using the element field definition.
  List<T> _validateElements(List<dynamic> list, JsonPath path, FieldInfo field) {
    return [
      for (var i = 0; i < list.length; ++i) elements.value({"value": list[i]}, path / i.toString()),
    ];
  }
}
