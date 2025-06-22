/// Extension methods for the List class.
extension ExtendIterable<T> on List<T> {
  /// Returns the first element that satisfies the given predicate, or null if no such element exists.
  ///
  /// This is equivalent to firstWhere with an orElse that returns null, but more concise.
  T? firstWhereOrNull(bool Function(T) test) => cast<T?>().firstWhere((i) => test(i as T), orElse: () => null);
}
