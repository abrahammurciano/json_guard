/// A union type that can hold a value of either type T1 or type T2.
///
/// Union provides a type-safe way to represent values that could be one of two different types, while keeping track of which type is currently stored. This is similar to union types in languages like Rust.
///
/// Example:
/// ```dart
/// Union<int, String> getValueFromConfig() {
///   // Return either an int or a string based on some condition
///   if (someCondition) {
///     return Union.first(42);
///   } else {
///     return Union.second("hello");
///   }
/// }
///
/// // Later, pattern match on the result
/// final result = getValueFromConfig();
/// final output = result.when(
///   first: (intValue) => "Got number: $intValue",
///   second: (stringValue) => "Got string: $stringValue",
/// );
/// ```
class Union<T1, T2> {
  /// The stored value of type T1, if this union represents the first type.
  final T1? _value1;

  /// The stored value of type T2, if this union represents the second type.
  final T2? _value2;

  /// Whether the union currently holds a value of type T1.
  final bool isFirst;

  /// Whether the union currently holds a value of type T2.
  bool get isSecond => !isFirst;

  /// Gets the value of type T1 if present, otherwise throws an exception.
  ///
  /// You should check [isFirst] before accessing this property.
  T1 get first => isFirst ? _value1 as T1 : throw StateError("Union<$T1, $T2> does not have a first value");

  /// Gets the value of type T2 if present, otherwise throws an exception.
  ///
  /// You should check [isSecond] before accessing this property.
  T2 get second => isSecond ? _value2 as T2 : throw StateError("Union<$T1, $T2> does not have a second value");

  /// Creates a union holding a value of type T1.
  const Union.first(T1 value) : _value1 = value, _value2 = null, isFirst = true;

  /// Creates a union holding a value of type T2.
  const Union.second(T2 value) : _value1 = null, _value2 = value, isFirst = false;

  /// Creates a union with the specified values and discriminator.
  ///
  /// The [isFirst] parameter determines which value is considered "active".
  const Union(this._value1, this._value2, {this.isFirst = true});

  /// Pattern matches on the union type to transform its value.
  ///
  /// This method applies the appropriate function based on which type is currently stored, allowing you to handle both cases in a type-safe way without explicit if/else statements.
  ///
  /// Parameters:
  /// - [first]: Function to apply if the union holds a value of type T1
  /// - [second]: Function to apply if the union holds a value of type T2
  ///
  /// Returns the result of applying the appropriate function to the stored value.
  R when<R>({required R Function(T1 value) first, required R Function(T2 value) second}) {
    return isFirst ? first(this.first) : second(this.second);
  }

  @override
  String toString() => isFirst ? "Union.first($_value1)" : "Union.second($_value2)";
}

/// Represents an optional value that may or may not be present.
///
/// Option provides a type-safe way to represent the absence of a value without using null. This is similar to Rust's Option, Scala's Option, or Swift's Optional type.
///
/// Option is used throughout JsonGuard to handle missing values, optional fields, and potential absence of data in a clear, explicit manner.
///
/// Example:
/// ```dart
/// Option<String> getUserEmail(int userId) {
///   final user = findUser(userId);
///   return user?.email != null ? Option.value(user!.email!) : Option.empty();
/// }
///
/// final emailOption = getUserEmail(123);
///
/// // Safe access with pattern matching
/// final message = emailOption.when(
///   value: (email) => "User email is $email",
///   empty: () => "User has no email",
/// );
///
/// // Safe access with fallback
/// final email = emailOption.or(() => "default@example.com");
/// ```
class Option<T> {
  /// The underlying union that stores either a value or null.
  final Union<T, Null> _value;

  /// Whether this option contains no value.
  bool get isEmpty => _value.isSecond;

  /// Whether this option contains a value.
  bool get hasValue => _value.isFirst;

  /// Gets the contained value if present, otherwise throws an exception.
  ///
  /// You should check [hasValue] before accessing this property, or use [or] or [when] for safe access.
  T get value => isEmpty ? throw StateError("Option<$T> is empty") : _value.first;

  /// Creates an option that may or may not contain a value.
  ///
  /// If [hasValue] is true, [value] must be non-null and of type T. If [hasValue] is false, [value] is ignored.
  ///
  /// In most cases, you should use [Option.empty], [Option.value], or [Option.maybe] instead.
  Option(T? value, bool hasValue)
    : assert(value is T || !hasValue, "Value must be of type T or hasValue must be false"),
      _value = hasValue ? Union.first(value as T) : Union.second(null);

  /// Creates an empty option representing the absence of a value.
  const Option.empty() : _value = const Union.second(null);

  /// Creates an option containing the specified value.
  ///
  /// The [value] parameter must be non-null.
  Option.value(T value) : this(value, true);

  /// Creates an option that contains the specified value only if it is not null.
  ///
  /// This is a convenience constructor that automatically handles null checking.
  Option.maybe(T? value) : this(value, value != null);

  /// Returns the contained value or the result of calling orElse if empty.
  ///
  /// This provides a safe way to access the value with a fallback.
  ///
  /// Parameters:
  /// - [orElse]: Function that produces a fallback value if this option is empty
  ///
  /// Returns either the contained value or the result of [orElse].
  T or(T Function() orElse) => _value.when(first: (value) => value, second: (_) => orElse());

  /// Pattern matches on the option to transform its value.
  ///
  /// This method provides a safe way to handle both the present and absent cases without explicit if/else statements or null checks.
  ///
  /// Parameters:
  /// - [value]: Function to apply if this option contains a value
  /// - [empty]: Function to apply if this option is empty
  ///
  /// Returns the result of applying the appropriate function.
  U when<U>({required U Function(T value) value, required U Function() empty}) {
    return _value.when(first: (v) => value(v), second: (_) => empty());
  }

  @override
  String toString() => isEmpty ? "Option.empty" : "Option.value($_value)";
}
