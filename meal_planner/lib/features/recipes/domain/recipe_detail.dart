import 'package:meal_planner/core/supabase/models/ingredient.dart';
import 'package:meal_planner/core/supabase/models/nutrition_info.dart';
import 'package:meal_planner/core/supabase/models/recipe.dart';
import 'package:meal_planner/core/supabase/models/recipe_step.dart';

class RecipeDetail {
  const RecipeDetail({
    required this.recipe,
    required this.ingredients,
    required this.steps,
    this.nutrition,
    this.photoDisplayUrl,
    this.forkedFromId,
  });

  final Recipe recipe;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final NutritionInfo? nutrition;
  final String? photoDisplayUrl;
  final String? forkedFromId;

  bool get isForked => forkedFromId != null;
}
