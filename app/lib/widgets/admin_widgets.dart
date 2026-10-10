import 'package:flutter/material.dart';

// Manager panel ki saari screens ke common helpers.

String errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

void showMessage(BuildContext context, String msg, {bool error = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? cs.error : null,
    ));
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('$what delete karna hai?'),
      content: const Text('Yeh wapas nahi aayega.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Edit / Delete wala 3-dot menu
class EditDeleteMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EditDeleteMenu(
      {super.key, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'edit') {
          onEdit();
        } else {
          onDelete();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'edit',
            child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
        PopupMenuItem(
            value: 'delete',
            child:
                ListTile(leading: Icon(Icons.delete), title: Text('Delete'))),
      ],
    );
  }
}

class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmptyHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: c),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: c)),
          ],
        ),
      ),
    );
  }
}

/// Dialog / form ke andar "Save" button jo saving ke waqt spinner dikhaye
class SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onPressed;
  final String label;

  const SaveButton({
    super.key,
    required this.saving,
    required this.onPressed,
    this.label = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: saving ? null : onPressed,
      child: saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}

/// Dialog / form ke andar error message (backend ka "pehle se hai" waghera)
class FormError extends StatelessWidget {
  final String? message;

  const FormError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(message!, style: TextStyle(color: cs.error))),
        ],
      ),
    );
  }
}

// ---------------- Validators ----------------

class V {
  static String? req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Zaroori hai' : null;

  static String? price(String? v) {
    final d = double.tryParse((v ?? '').trim());
    if (d == null) return 'Number likho';
    if (d < 0) return 'Minus nahi ho sakta';
    return null;
  }

  static String? percent(String? v) {
    final d = double.tryParse((v ?? '').trim());
    if (d == null) return 'Number likho';
    if (d < 0 || d > 100) return '0 se 100 ke beech';
    return null;
  }

  static String? Function(String?) intMin(int min) => (v) {
        final n = int.tryParse((v ?? '').trim());
        if (n == null) return 'Poora number likho';
        if (n < min) return 'Kam az kam $min';
        return null;
      };

  static String? pin(String? v) =>
      RegExp(r'^\d{4}$').hasMatch((v ?? '').trim()) ? null : '4 digits';
}
