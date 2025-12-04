import 'package:flutter/material.dart';

class AppSnack {
  // Call this for errors
  static void error(BuildContext ctx, String message) {
    _show(ctx, message,
      bg: Colors.red,            // distinct error color
      fg: Colors.white,
      icon: Icons.error_outline,
    );
  }

  // Call this for success
  static void success(BuildContext ctx, String message, {Color? primary}) {
    _show(ctx, message,
      bg: primary ?? Theme.of(ctx).colorScheme.primary, // your green brand color
      fg: Colors.white,
      icon: Icons.check_circle_outline,
    );
  }

  static void _show(BuildContext ctx, String message,
      {required Color bg, required Color fg, required IconData icon}) {
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: TextStyle(color: fg))),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
