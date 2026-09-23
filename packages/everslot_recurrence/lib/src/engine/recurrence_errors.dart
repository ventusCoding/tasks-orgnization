import 'package:everslot_recurrence/src/rule/rule_validator.dart';

/// Thrown when a rule can't be expanded (e.g. `interval: 0`, `byMonth: [13]`).
final class InvalidRuleException implements Exception {
  const new(this.issues);

  /// The fatal validation issues.
  final List<RuleIssue> issues;

  @override
  String toString() => 'InvalidRuleException(${issues.join(', ')})';
}

/// Thrown when a query would return more occurrences than the engine's cap
/// (default 10 000). Pass an explicit `limit` or narrow the range.
final class RecurrenceLimitExceeded implements Exception {
  const new(this.limit);

  /// The cap that was hit.
  final int limit;

  @override
  String toString() =>
      'RecurrenceLimitExceeded: more than $limit occurrences in one call; '
      'narrow the range or pass an explicit limit';
}
