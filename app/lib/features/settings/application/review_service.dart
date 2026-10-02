import 'package:everslot/core/providers.dart';
import 'package:everslot/features/settings/data/review_prompt_store.dart';
import 'package:everslot/features/settings/domain/review_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:in_app_review/in_app_review.dart';

/// The OS rating sheet / store page (faked in tests).
abstract interface class ReviewPort {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing();
}

class InAppReviewPort implements ReviewPort {
  final _review = InAppReview.instance;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _review.isAvailable();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> requestReview() => _review.requestReview();

  @override
  Future<void> openStoreListing() => _review.openStoreListing();
}

final reviewPortProvider = Provider<ReviewPort>((ref) => InAppReviewPort());

final reviewServiceProvider = Provider<ReviewService>(
  (ref) => ReviewService(ref.watch(reviewPortProvider), ReviewPromptStore(ref.watch(appDatabaseProvider)), ref.read),
);

/// "Rate Everslot" (T8.3.13): on demand from About, automatically at most once per 90 days
/// ([ReviewPolicy]) after a happy moment (a 30-day streak).
class ReviewService {
  ReviewService(this._port, this._store, this._read);

  final ReviewPort _port;
  final ReviewPromptStore _store;
  final T Function<T>(ProviderListenable<T> provider) _read;

  DateTime get _now => _read(clockProvider).nowUtc();

  /// The user asked: the in-app sheet when the OS would show it, else the store page (the OS
  /// silently ignores sheet requests once its own quota is used).
  Future<void> rateFromSettings() async {
    final now = _now;
    if (await _port.isAvailable() && ReviewPolicy.canAutoPrompt(now: now, lastPromptAt: await _store.lastPromptAt())) {
      await _store.setLastPromptAt(now);
      await _port.requestReview();
    } else {
      await _port.openStoreListing();
    }
  }

  /// Asks on its own when [ReviewPolicy] allows it; returns whether the sheet was requested.
  Future<bool> maybeAutoPrompt() async {
    final now = _now;
    if (!ReviewPolicy.canAutoPrompt(now: now, lastPromptAt: await _store.lastPromptAt())) return false;
    if (!await _port.isAvailable()) return false;
    await _store.setLastPromptAt(now);
    await _port.requestReview();
    return true;
  }
}
