import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/core/utils/date_utils.dart';
import 'package:meal_planner/features/planner/domain/planner_constants.dart';
import 'package:meal_planner/features/planner/domain/slot_item.dart';
import 'package:meal_planner/features/planner/presentation/planner_provider.dart';
import 'package:meal_planner/features/planner/presentation/widgets/planner_slot_card.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(currentWeekProvider);
    final planAsync = ref.watch(weeklyPlanProvider);
    final slotsAsync = ref.watch(planSlotsProvider);
    final isCurrentWeek =
        weekStart == startOfIsoWeek(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificador'),
        actions: [
          if (isCurrentWeek)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Esta semana'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (_) => Column(
          children: [
            _WeekNavigationHeader(weekStart: weekStart),
            Expanded(
              child: slotsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (slots) => _PlannerGrid(
                  weekStart: weekStart,
                  slots: slots,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekNavigationHeader extends ConsumerWidget {
  const _WeekNavigationHeader({required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(currentWeekProvider.notifier).state =
                  weekStart.subtract(const Duration(days: 7));
            },
          ),
          Expanded(
            child: Text(
              formatWeekRange(weekStart),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(currentWeekProvider.notifier).state =
                  weekStart.add(const Duration(days: 7));
            },
          ),
        ],
      ),
    );
  }
}

class _PlannerGrid extends StatelessWidget {
  const _PlannerGrid({
    required this.weekStart,
    required this.slots,
  });

  final DateTime weekStart;
  final List<SlotItem> slots;

  List<SlotItem> _slotsForCell(int dayOfWeek, String mealType) {
    return slots
        .where(
          (item) =>
              item.slot.dayOfWeek == dayOfWeek &&
              item.slot.mealType == mealType,
        )
        .toList()
      ..sort((a, b) => a.slot.position.compareTo(b.slot.position));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(110),
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                children: [
                  const SizedBox(width: 72, height: 40),
                  for (var day = 1; day <= 7; day++)
                    _DayHeaderCell(
                      label: DayOfWeek.labels[day - 1],
                      date: weekStart.add(Duration(days: day - 1)),
                    ),
                ],
              ),
              for (final mealType in MealType.all)
                TableRow(
                  children: [
                    _MealLabelCell(label: MealType.label(mealType)),
                    for (var day = 1; day <= 7; day++)
                      PlannerSlotCard(
                        dayOfWeek: day,
                        mealType: mealType,
                        slots: _slotsForCell(day, mealType),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: isToday
          ? BoxDecoration(color: colorScheme.primaryContainer)
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
          ),
          Text(
            '${date.day}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MealLabelCell extends StatelessWidget {
  const _MealLabelCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 96,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}
