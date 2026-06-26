import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:meal_planner/core/utils/logger.dart';

/// Prompts the native store review dialog with a cooldown between requests.
///
/// Call [onFirstWeekCompleted] from the planner once the user finishes their
/// first planned week (Fase 4).
abstract final class ReviewPromptService {
  static const _lastPromptKey = 'review.last_prompt_at';
  static const _firstWeekCompletedKey = 'review.first_week_completed';
  static const cooldownDays = 6;

  static const _storage = FlutterSecureStorage();
  static final _inAppReview = InAppReview.instance;

  /// Marks the first-week milestone and shows the review prompt if allowed.
  static Future<void> onFirstWeekCompleted() async {
    final alreadyCompleted =
        await _storage.read(key: _firstWeekCompletedKey) == 'true';
    if (alreadyCompleted) return;

    await _storage.write(key: _firstWeekCompletedKey, value: 'true');
    await maybeRequestReview(force: true);
  }

  /// Shows the review prompt when available and outside the cooldown window.
  static Future<void> maybeRequestReview({bool force = false}) async {
    if (!await _inAppReview.isAvailable()) {
      log.d('In-app review not available on this platform');
      return;
    }

    if (!force && !await _isOutsideCooldown()) return;

    await _inAppReview.requestReview();
    await _storage.write(
      key: _lastPromptKey,
      value: DateTime.now().toUtc().toIso8601String(),
    );
    log.i('In-app review prompt requested');
  }

  static Future<bool> _isOutsideCooldown() async {
    final lastPrompt = await _storage.read(key: _lastPromptKey);
    if (lastPrompt == null) return true;

    final lastDate = DateTime.tryParse(lastPrompt);
    if (lastDate == null) return true;

    return DateTime.now().toUtc().difference(lastDate).inDays >= cooldownDays;
  }
}
