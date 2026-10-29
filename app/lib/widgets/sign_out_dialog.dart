import 'package:flutter/material.dart';

Future<bool> confirmSignOut(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign out karna hai?'),
      content: const Text('Agla banda apni Employee ID aur PIN se login karega.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Nahi'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Haan, sign out'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
