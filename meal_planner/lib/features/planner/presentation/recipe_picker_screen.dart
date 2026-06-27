import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/core/supabase/models/recipe.dart';
import 'package:meal_planner/features/planner/presentation/planner_provider.dart';
import 'package:meal_planner/features/recipes/presentation/recipe_provider.dart';

class RecipePickerSheet extends ConsumerStatefulWidget {
  const RecipePickerSheet({
    required this.dayOfWeek,
    required this.mealType,
    super.key,
  });

  final int dayOfWeek;
  final String mealType;

  @override
  ConsumerState<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<RecipePickerSheet> {
  final _searchController = TextEditingController();
  List<Recipe> _filteredRecipes = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text;
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredRecipes = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results =
        await ref.read(recipesProvider.notifier).search(query);
    if (!mounted) return;
    setState(() {
      _filteredRecipes = results;
      _isSearching = false;
    });
  }

  Future<void> _selectRecipe(Recipe recipe) async {
    final servings = await showDialog<int>(
      context: context,
      builder: (context) => _ServingsDialog(defaultServings: recipe.servings),
    );

    if (servings == null || !mounted) return;

    await ref.read(planSlotsProvider.notifier).addSlot(
          dayOfWeek: widget.dayOfWeek,
          mealType: widget.mealType,
          recipeId: recipe.id,
          servings: servings,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    final displayRecipes = _searchController.text.trim().isEmpty
        ? recipesAsync.valueOrNull ?? []
        : _filteredRecipes;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Elegir receta',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar receta...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (_) {
                if (_isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (displayRecipes.isEmpty) {
                  return Center(
                    child: Text(
                      _searchController.text.trim().isEmpty
                          ? 'No tienes recetas. Créalas en el recetario.'
                          : 'Sin resultados',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayRecipes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final recipe = displayRecipes[index];
                    return ListTile(
                      title: Text(recipe.title),
                      subtitle: Text('${recipe.servings} raciones'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selectRecipe(recipe),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServingsDialog extends StatefulWidget {
  const _ServingsDialog({required this.defaultServings});

  final int defaultServings;

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.defaultServings.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un número válido de raciones')),
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Raciones'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Número de raciones',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
