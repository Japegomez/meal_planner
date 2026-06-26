import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner/core/review/review_prompt_service.dart';

void main() {
  group('ReviewPromptService', () {
    test('cooldown is 6 days', () {
      expect(ReviewPromptService.cooldownDays, 6);
    });
  });
}
