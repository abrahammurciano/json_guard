/// A union type that can hold a value of either type T1 or type T2.
///
/// This is a discriminated union that keeps track of which type is currently stored.
class Union<T1, T2> {
  final T1? _value1;
  final T2? _value2;

  /// Whether the union currently holds a value of type T1.
  final bool isFirst;

  /// Whether the union currently holds a value of type T2.
  bool get isSecond => !isFirst;

  /// Gets the value of type T1 if present, otherwise throws an exception.
  T1 get first => isFirst ? _value1 as T1 : throw StateError("Union<$T1, $T2> does not have a first value");

  /// Gets the value of type T2 if present, otherwise throws an exception.
  T2 get second => isSecond ? _value2 as T2 : throw StateError("Union<$T1, $T2> does not have a second value");

  /// Creates a union holding a value of type T1.
  const Union.first(T1 value) : _value1 = value, _value2 = null, isFirst = true;

  /// Creates a union holding a value of type T2.
  const Union.second(T2 value) : _value1 = null, _value2 = value, isFirst = false;

  /// Creates a union with the specified values and discriminator.
  const Union(this._value1, this._value2, {this.isFirst = true});

  /// Pattern matches on the union type to transform its value.
  ///
  /// Applies the appropriate function based on which type is currently stored.
  R when<R>({required R Function(T1 value) first, required R Function(T2 value) second}) {
    return isFirst ? first(this.first) : second(this.second);
  }

  @override
  String toString() => isFirst ? "Union.first($_value1)" : "Union.second($_value2)";
}

/// Represents an optional value that may or may not be present.
///
/// This is similar to Rust's Option or Scala's Option type, providing a type-safe
/// way to represent the absence of a value without using null.
class Option<T> {
  final Union<T, Null> _value;

  /// Whether this option contains no value.
  bool get isEmpty => _value.isSecond;

  /// Whether this option contains a value.
  bool get hasValue => _value.isFirst;

  /// Gets the contained value if present, otherwise throws an exception.
  T get value => isEmpty ? throw StateError("Option<$T> is empty") : _value.first;

  /// Creates an option that may or may not contain a value.
  Option(T? value, bool hasValue)
    : assert(value is T || !hasValue, "Value must be of type T or hasValue must be false"),
      _value = hasValue ? Union.first(value as T) : Union.second(null);

  /// Creates an empty option.
  const Option.empty() : _value = const Union.second(null);

  /// Creates an option containing the specified value.
  Option.value(T value) : this(value, true);

  /// Creates an option that contains the specified value only if it is not null.
  Option.maybe(T? value) : this(value, value != null);

  /// Returns the contained value or the result of calling orElse if empty.
  T or(T Function() orElse) => _value.when(first: (value) => value, second: (_) => orElse());

  /// Pattern matches on the option to transform its value.
  U when<U>({required U Function(T value) value, required U Function() empty}) {
    return _value.when(first: (v) => value(v), second: (_) => empty());
  }

  @override
  String toString() => isEmpty ? "Option.empty" : "Option.value($_value)";
}
