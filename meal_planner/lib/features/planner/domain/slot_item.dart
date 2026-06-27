import 'package:meal_planner/core/supabase/models/plan_slot.dart';

class SlotItem {
  const SlotItem({
    required this.slot,
    this.recipeTitle,
  });

  final PlanSlot slot;
  final String? recipeTitle;

  factory SlotItem.fromJson(Map<String, dynamic> json) {
    final recipeJson = json['recipes'];
    String? title;
    if (recipeJson is Map<String, dynamic>) {
      title = recipeJson['title'] as String?;
    }

    return SlotItem(
      slot: PlanSlot.fromJson(json),
      recipeTitle: title,
    );
  }
}
