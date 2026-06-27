import 'package:meal_planner/core/supabase/models/shopping_item.dart';
import 'package:meal_planner/core/supabase/models/shopping_list.dart';
import 'package:meal_planner/core/supabase/supabase_client.dart';

class ShoppingRepository {
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

  Future<List<ShoppingItem>> getItemsForList(String listId) async {
    final data = await supabase
        .from(ShoppingItem.table_name)
        .select()
        .eq(ShoppingItem.c_shoppingListId, listId)
        .order(ShoppingItem.c_isChecked)
        .order(ShoppingItem.c_category)
        .order(ShoppingItem.c_name);

    return ShoppingItem.converter(
      (data as List).cast<Map<String, dynamic>>(),
    );
  }

  Future<void> toggleItem(String id, bool isChecked) async {
    await supabase
        .from(ShoppingItem.table_name)
        .update({ShoppingItem.c_isChecked: isChecked})
        .eq(ShoppingItem.c_id, id);
  }

  Future<ShoppingItem> addManualItem({
    required String listId,
    required String name,
    num? quantity,
    String? unit,
    String? category,
  }) async {
    final data = await supabase
        .from(ShoppingItem.table_name)
        .insert(
          ShoppingItem.insert(
            shoppingListId: listId,
            name: name,
            quantity: quantity,
            unit: unit,
            category: category,
            isManual: true,
          ),
        )
        .select()
        .single();

    return ShoppingItem.fromJson(data);
  }

  Future<ShoppingItem> updateItem({
    required String id,
    required String name,
    num? quantity,
    String? unit,
    String? category,
  }) async {
    final data = await supabase
        .from(ShoppingItem.table_name)
        .update(
          ShoppingItem.update(
            name: name,
            quantity: quantity,
            unit: unit,
            category: category,
          ),
        )
        .eq(ShoppingItem.c_id, id)
        .select()
        .single();

    return ShoppingItem.fromJson(data);
  }

  Future<void> deleteItem(String id) async {
    await supabase.from(ShoppingItem.table_name).delete().eq(ShoppingItem.c_id, id);
  }

  Future<void> clearList(String listId) async {
    await supabase
        .from(ShoppingItem.table_name)
        .delete()
        .eq(ShoppingItem.c_shoppingListId, listId);
  }
}
