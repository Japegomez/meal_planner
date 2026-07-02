import 'package:flutter/material.dart';

/// Small circular bullet for ingredient lists (app primary green).
class IngredientBullet extends StatelessWidget {
  const IngredientBullet({this.muted = false, super.key});

  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = muted
        ? colorScheme.onSurface.withValues(alpha: 0.28)
        : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 7, right: 10),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: muted
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
      ),
    );
  }
}
