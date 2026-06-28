import 'package:meal_planner/core/supabase/models/ingredient.dart';
import 'package:meal_planner/core/supabase/models/nutrition_info.dart';
import 'package:meal_planner/core/supabase/models/recipe.dart';
import 'package:meal_planner/core/supabase/models/recipe_step.dart';

class PublicRecipeDetail {
  const PublicRecipeDetail({
    required this.recipe,
    required this.ingredients,
    required this.steps,
    this.nutrition,
    this.photoDisplayUrl,
    required this.authorName,
    required this.avgScore,
    required this.ratingCount,
    this.myRating,
  });

  final Recipe recipe;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final NutritionInfo? nutrition;
  final String? photoDisplayUrl;
  final String authorName;
  final double avgScore;
  final int ratingCount;
  final int? myRating;
}
