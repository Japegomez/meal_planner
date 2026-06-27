import 'package:meal_planner/core/supabase/models/ingredient.dart';
import 'package:meal_planner/core/supabase/models/plan_slot.dart';
import 'package:meal_planner/core/supabase/models/recipe.dart';
import 'package:meal_planner/core/supabase/models/shopping_item.dart';
import 'package:meal_planner/core/supabase/models/shopping_list.dart';
import 'package:meal_planner/core/supabase/models/weekly_plan.dart';
import 'package:meal_planner/core/supabase/supabase_client.dart';
import 'package:meal_planner/features/planner/domain/slot_item.dart';

class PlannerRepository {
  Future<WeeklyPlan> getOrCreateWeeklyPlan({
    required DateTime weekStart,
    required String userId,
    String? householdId,
  }) async {
    final dateStr = _formatDate(weekStart);

    final Map<String, dynamic>? existing;
    if (householdId != null) {
      existing = await supabase
          .from(WeeklyPlan.table_name)
          .select()
          .eq(WeeklyPlan.c_householdId, householdId)
          .eq(WeeklyPlan.c_weekStart, dateStr)
          .maybeSingle();
    } else {
      existing = await supabase
          .from(WeeklyPlan.table_name)
          .select()
          .eq(WeeklyPlan.c_userId, userId)
          .eq(WeeklyPlan.c_weekStart, dateStr)
          .maybeSingle();
    }

    if (existing != null) {
      return WeeklyPlan.fromJson(existing);
    }

    final data = await supabase
        .from(WeeklyPlan.table_name)
        .insert(
          WeeklyPlan.insert(
            weekStart: weekStart,
            householdId: householdId,
            userId: householdId == null ? userId : null,
          ),
        )
        .select()
        .single();

    return WeeklyPlan.fromJson(data);
  }

  Future<List<SlotItem>> getSlotsForPlan(String planId) async {
    final data = await supabase
        .from(PlanSlot.table_name)
        .select('*, recipes(id, title, servings)')
        .eq(PlanSlot.c_planId, planId)
        .order(PlanSlot.c_dayOfWeek)
        .order(PlanSlot.c_mealType)
        .order(PlanSlot.c_position);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(SlotItem.fromJson)
        .toList();
  }

  Future<PlanSlot> addSlot({
    required String planId,
    required int dayOfWeek,
    required String mealType,
    String? recipeId,
    required int servings,
    required String userId,
    String? householdId,
    bool isLeftover = false,
    String? notes,
  }) async {
    final existingSlots = await getSlotsForPlan(planId);
    final position = existingSlots
        .where(
          (item) =>
              item.slot.dayOfWeek == dayOfWeek &&
              item.slot.mealType == mealType,
        )
        .length;

    final data = await supabase
        .from(PlanSlot.table_name)
        .insert(
          PlanSlot.insert(
            planId: planId,
            dayOfWeek: dayOfWeek,
            mealType: mealType,
            recipeId: recipeId,
            servings: servings,
            position: position,
            isLeftover: isLeftover,
            notes: notes,
          ),
        )
        .select()
        .single();

    final slot = PlanSlot.fromJson(data);

    if (recipeId != null && !isLeftover) {
      await _syncShoppingListAdd(
        slot: slot,
        recipeId: recipeId,
        servings: servings,
        userId: userId,
        householdId: householdId,
      );
    }

    return slot;
  }

  Future<void> removeSlot(String slotId) async {
    await supabase
        .from(ShoppingItem.table_name)
        .delete()
        .eq(ShoppingItem.c_planSlotId, slotId);

    await supabase.from(PlanSlot.table_name).delete().eq(PlanSlot.c_id, slotId);
  }

  Future<ShoppingList> getOrCreateShoppingList({
    required String userId,
    String? householdId,
  }) async {
    final Map<String, dynamic>? existing;
    if (householdId != null) {
      existing = await supabase
          .from(ShoppingList.table_name)
          .select()
          .eq(ShoppingList.c_householdId, householdId)
          .order(ShoppingList.c_createdAt, ascending: false)
          .limit(1)
          .maybeSingle();
    } else {
      existing = await supabase
          .from(ShoppingList.table_name)
          .select()
          .eq(ShoppingList.c_userId, userId)
          .order(ShoppingList.c_createdAt, ascending: false)
          .limit(1)
          .maybeSingle();
    }

    if (existing != null) {
      return ShoppingList.fromJson(existing);
    }

    final data = await supabase
        .from(ShoppingList.table_name)
        .insert(
          ShoppingList.insert(
            householdId: householdId,
            userId: householdId == null ? userId : null,
          ),
        )
        .select()
        .single();

    return ShoppingList.fromJson(data);
  }

  Future<void> _syncShoppingListAdd({
    required PlanSlot slot,
    required String recipeId, // never null when this method is called
    required int servings,
    required String userId,
    String? householdId,
  }) async {
    final list = await getOrCreateShoppingList(
      userId: userId,
      householdId: householdId,
    );

    final recipeData = await supabase
        .from(Recipe.table_name)
        .select('${Recipe.c_servings}')
        .eq(Recipe.c_id, recipeId)
        .single();

    final recipeServings = int.parse(recipeData[Recipe.c_servings].toString());
    if (recipeServings <= 0) return;

    final scale = servings / recipeServings;

    final ingredientsData = await supabase
        .from(Ingredient.table_name)
        .select()
        .eq(Ingredient.c_recipeId, recipeId)
        .order(Ingredient.c_position);

    final ingredients = Ingredient.converter(
      (ingredientsData as List).cast<Map<String, dynamic>>(),
    );

    if (ingredients.isEmpty) return;

    final rows = ingredients.map((ingredient) {
      final scaledQty = ingredient.quantity != null
          ? ingredient.quantity! * scale
          : null;

      return ShoppingItem.insert(
        shoppingListId: list.id,
        name: ingredient.name,
        quantity: scaledQty,
        unit: ingredient.unit,
        category: ingredient.category,
        isManual: false,
        planSlotId: slot.id,
        ingredientId: ingredient.id,
      );
    }).toList();

    await supabase.from(ShoppingItem.table_name).insert(rows);
  }

  String _formatDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
