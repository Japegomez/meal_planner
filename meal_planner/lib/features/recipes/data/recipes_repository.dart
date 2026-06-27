import 'package:meal_planner/core/supabase/models/recipe.dart';
import 'package:meal_planner/core/supabase/supabase_client.dart';

class RecipesRepository {
  Future<List<Recipe>> fetchRecipes(String userId) async {
    final data = await supabase
        .from(Recipe.table_name)
        .select()
        .eq(Recipe.c_userId, userId)
        .order(Recipe.c_title);

    return Recipe.converter((data as List).cast<Map<String, dynamic>>());
  }

  Future<List<Recipe>> searchRecipes({
    required String userId,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return fetchRecipes(userId);

    final data = await supabase
        .from(Recipe.table_name)
        .select()
        .eq(Recipe.c_userId, userId)
        .ilike(Recipe.c_title, '%$trimmed%')
        .order(Recipe.c_title);

    return Recipe.converter((data as List).cast<Map<String, dynamic>>());
  }
}
