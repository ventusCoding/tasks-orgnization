/// When Everslot may ask for a store rating on its own (T8.3.13).
abstract final class ReviewPolicy {
  /// Never more than one automatic prompt per this period.
  static const minInterval = Duration(days: 90);

  /// Whether an automatic prompt is allowed at [now].
  static bool canAutoPrompt({required DateTime now, required DateTime? lastPromptAt}) =>
      lastPromptAt == null || now.difference(lastPromptAt) >= minInterval;
}
