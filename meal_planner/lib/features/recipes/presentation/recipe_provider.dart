import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/core/supabase/models/recipe.dart';
import 'package:meal_planner/features/auth/domain/auth_state.dart';
import 'package:meal_planner/features/auth/presentation/auth_provider.dart';
import 'package:meal_planner/features/recipes/data/recipes_repository.dart';

final recipesRepositoryProvider = Provider<RecipesRepository>((ref) {
  return RecipesRepository();
});

final recipesProvider =
    AsyncNotifierProvider<RecipesNotifier, List<Recipe>>(RecipesNotifier.new);

class RecipesNotifier extends AsyncNotifier<List<Recipe>> {
  RecipesRepository get _repository => ref.read(recipesRepositoryProvider);

  String? get _userId {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is AuthAuthenticated) return authState.user.id;
    return null;
  }

  @override
  Future<List<Recipe>> build() async {
    ref.watch(authStateProvider);
    final userId = _userId;
    if (userId == null) return [];
    return _repository.fetchRecipes(userId);
  }

  Future<List<Recipe>> search(String query) async {
    final userId = _userId;
    if (userId == null) return [];
    return _repository.searchRecipes(userId: userId, query: query);
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.fetchRecipes(userId));
  }
}
