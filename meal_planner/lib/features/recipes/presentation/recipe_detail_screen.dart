import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_planner/core/supabase/models/ingredient.dart';
import 'package:meal_planner/core/supabase/models/nutrition_info.dart';
import 'package:meal_planner/core/supabase/models/recipe_step.dart';
import 'package:meal_planner/features/recipes/presentation/recipe_provider.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      body: detailAsync.when(
        data: (detail) => _RecipeDetailBody(
          recipeId: recipeId,
          photoUrl: detail.photoDisplayUrl,
          title: detail.recipe.title,
          servings: detail.recipe.servings,
          prepTime: detail.recipe.prepTime,
          cookTime: detail.recipe.cookTime,
          tags: detail.recipe.tags,
          ingredients: detail.ingredients,
          steps: detail.steps,
          nutrition: detail.nutrition,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _RecipeDetailBody extends ConsumerWidget {
  const _RecipeDetailBody({
    required this.recipeId,
    required this.photoUrl,
    required this.title,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
  });

  final String recipeId;
  final String? photoUrl;
  final String title;
  final int servings;
  final int? prepTime;
  final int? cookTime;
  final List<String> tags;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final NutritionInfo? nutrition;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('¿Seguro que quieres eliminar "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(recipesRepositoryProvider).deleteRecipe(recipeId);
    ref.invalidate(recipeListProvider);
    ref.invalidate(recipeTagsProvider);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: photoUrl != null ? 240 : 120,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/home/recipes/$recipeId/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(title),
            background: photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  )
                : null,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.people_outline,
                      label: '$servings raciones',
                    ),
                    if (prepTime != null)
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: 'Prep: $prepTime min',
                      ),
                    if (cookTime != null)
                      _InfoChip(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Cocción: $cookTime min',
                      ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Ingredientes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (ingredients.isEmpty)
                  const Text('Sin ingredientes')
                else
                  ...ingredients.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${entry.key + 1}. ${_formatIngredient(entry.value)}',
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                Text(
                  'Elaboración',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (steps.isEmpty)
                  const Text('Sin pasos')
                else
                  ...steps.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                child: Text('${entry.key + 1}'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(entry.value.description)),
                            ],
                          ),
                        ),
                      ),
                if (nutrition != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Nutrición (por ración)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _NutritionGrid(nutrition: nutrition!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatIngredient(Ingredient ingredient) {
    final parts = <String>[];
    if (ingredient.quantity != null) parts.add(ingredient.quantity.toString());
    if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
      parts.add(ingredient.unit!);
    }
    parts.add(ingredient.name);
    if (ingredient.category != null && ingredient.category!.isNotEmpty) {
      parts.add('(${ingredient.category})');
    }
    return parts.join(' ');
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.nutrition});

  final NutritionInfo nutrition;

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String?>>[
      MapEntry('Calorías', _fmt(nutrition.calories, 'kcal')),
      MapEntry('Proteínas', _fmt(nutrition.protein, 'g')),
      MapEntry('Carbohidratos', _fmt(nutrition.carbohydrates, 'g')),
      MapEntry('Grasas', _fmt(nutrition.fat, 'g')),
      MapEntry('Fibra', _fmt(nutrition.fiber, 'g')),
    ].where((e) => e.value != null).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Chip(
              label: Text('${item.key}: ${item.value}'),
            ),
          )
          .toList(),
    );
  }

  String? _fmt(num? value, String unit) {
    if (value == null) return null;
    return '$value $unit';
  }
}
