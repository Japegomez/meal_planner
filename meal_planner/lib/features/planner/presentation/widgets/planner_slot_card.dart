import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/features/planner/domain/slot_item.dart';
import 'package:meal_planner/features/planner/presentation/planner_provider.dart';
import 'package:meal_planner/features/planner/presentation/recipe_picker_screen.dart';

class PlannerSlotCard extends ConsumerWidget {
  const PlannerSlotCard({
    required this.dayOfWeek,
    required this.mealType,
    required this.slots,
    super.key,
  });

  final int dayOfWeek;
  final String mealType;
  final List<SlotItem> slots;

  Future<void> _openRecipePicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RecipePickerSheet(
        dayOfWeek: dayOfWeek,
        mealType: mealType,
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    SlotItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar receta'),
        content: Text(
          '¿Quitar "${item.recipeTitle ?? 'esta receta'}" del planificador?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(planSlotsProvider.notifier).removeSlot(item.slot.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 96,
      padding: const EdgeInsets.all(4),
      child: slots.isEmpty
          ? Center(
              child: IconButton.outlined(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _openRecipePicker(context, ref),
                tooltip: 'Añadir receta',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: slots.length == 1
                      ? _RecipeChip(
                          item: slots.first,
                          onRemove: () => _confirmRemove(context, ref, slots.first),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: slots.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final item = slots[index];
                            return SizedBox(
                              width: 96,
                              child: _RecipeChip(
                                item: item,
                                onRemove: () =>
                                    _confirmRemove(context, ref, item),
                              ),
                            );
                          },
                        ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.add, size: 18, color: colorScheme.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => _openRecipePicker(context, ref),
                    tooltip: 'Añadir otra receta',
                  ),
                ),
              ],
            ),
    );
  }
}

class _RecipeChip extends StatelessWidget {
  const _RecipeChip({
    required this.item,
    required this.onRemove,
  });

  final SlotItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final title = item.recipeTitle ?? 'Receta';

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(title)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
