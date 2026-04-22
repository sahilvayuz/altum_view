import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:flutter/material.dart';

/// Shows a dialog for creating or renaming a room.
/// Returns the entered name or null if cancelled.
Future<String?> showRoomNameDialog(
  BuildContext context, {
  String? initialName,
}) {
  final ctrl = TextEditingController(text: initialName);
  final isEdit = initialName != null;

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        isEdit ? 'Rename Room' : 'New Room',
        style: const TextStyle(
            color: AppTheme.onSurface, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Room name',
          filled: true,
          fillColor: AppTheme.surfaceCard2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
        onSubmitted: (v) {
          final name = v.trim();
          if (name.isNotEmpty) Navigator.pop(ctx, name);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.onSurfaceSub)),
        ),
        TextButton(
          onPressed: () {
            final name = ctrl.text.trim();
            if (name.isNotEmpty) Navigator.pop(ctx, name);
          },
          child: Text(
            isEdit ? 'Save' : 'Create',
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
