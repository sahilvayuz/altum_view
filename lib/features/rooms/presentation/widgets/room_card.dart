import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:altum_view/features/rooms/service/room_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.house_fill,
                  color: AppTheme.primary, size: 22),
            ),

            const SizedBox(width: 14),

            // Name + camera count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${room.cameraCount} camera${room.cameraCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.onSurfaceSub, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz,
                  color: AppTheme.onSurfaceSub),
              color: AppTheme.surfaceCard2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'rename') onRename();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(children: [
                    Icon(CupertinoIcons.pencil,
                        color: AppTheme.primary, size: 16),
                    SizedBox(width: 10),
                    Text('Rename',
                        style: TextStyle(color: AppTheme.onSurface)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(CupertinoIcons.trash,
                        color: AppTheme.error, size: 16),
                    SizedBox(width: 10),
                    Text('Delete',
                        style: TextStyle(color: AppTheme.error)),
                  ]),
                ),
              ],
            ),

            const Icon(CupertinoIcons.chevron_right,
                color: AppTheme.onSurfaceSub, size: 16),
          ],
        ),
      ),
    );
  }
}
