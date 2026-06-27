import 'package:flutter/material.dart';

class ServingsResult {
  const ServingsResult({required this.servings, this.isLeftover = false});

  final int servings;
  final bool isLeftover;
}

/// Shown after selecting a recipe: asks for number of servings and whether
/// this is a leftover (skips shopping-list sync when true).
Future<ServingsResult?> showServingsDialog(
  BuildContext context, {
  required int defaultServings,
}) {
  return showDialog<ServingsResult>(
    context: context,
    builder: (context) => _ServingsDialog(defaultServings: defaultServings),
  );
}

/// Shown when the user taps "Añadir texto" in the recipe picker.
/// Returns notes text + servings, or null if cancelled.
Future<({String notes, int servings})?> showAddTextDialog(
  BuildContext context,
) {
  return showDialog<({String notes, int servings})>(
    context: context,
    builder: (context) => const _AddTextDialog(),
  );
}

// ─── Servings dialog ──────────────────────────────────────────────────────────

class _ServingsDialog extends StatefulWidget {
  const _ServingsDialog({required this.defaultServings});

  final int defaultServings;

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  late final TextEditingController _controller;
  bool _isLeftover = false;

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
    Navigator.pop(context, ServingsResult(servings: value, isLeftover: _isLeftover));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Raciones'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Número de raciones',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 12),
          _LeftoverCheckbox(
            value: _isLeftover,
            onChanged: (v) => setState(() => _isLeftover = v ?? false),
          ),
        ],
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

// ─── Add-text dialog ──────────────────────────────────────────────────────────

class _AddTextDialog extends StatefulWidget {
  const _AddTextDialog();

  @override
  State<_AddTextDialog> createState() => _AddTextDialogState();
}

class _AddTextDialogState extends State<_AddTextDialog> {
  final _notesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');

  @override
  void dispose() {
    _notesController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  void _confirm() {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para la comida')),
      );
      return;
    }
    final servings = int.tryParse(_servingsController.text.trim()) ?? 1;
    Navigator.pop(context, (
      notes: notes,
      servings: servings > 0 ? servings : 1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir texto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Nombre (ej. Pedido a domicilio)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _servingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Raciones',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}

// ─── Shared checkbox ─────────────────────────────────────────────────────────

class _LeftoverCheckbox extends StatelessWidget {
  const _LeftoverCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Son sobras',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'No se añadirán ingredientes a la lista de la compra',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
