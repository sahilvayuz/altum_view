import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:altum_view/features/device_connection/controller/device_connection_controller.dart';
import 'package:altum_view/features/device_connection/presentation/screens/device_connection_screen.dart';
import 'package:altum_view/features/rooms/controller/room_controller.dart';
import 'package:altum_view/features/rooms/presentation/screens/room_detail_screen.dart';
import 'package:altum_view/features/rooms/presentation/widgets/room_card.dart';
import 'package:altum_view/features/rooms/presentation/widgets/room_name_dialog.dart';
import 'package:altum_view/features/rooms/service/room_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch on first build, after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomController>().fetchRooms();
    });
  }

  Future<void> _createRoom() async {
    final name = await showRoomNameDialog(context);
    if (name == null || !mounted) return;
    final ok = await context.read<RoomController>().createRoom(name);
    if (!ok && mounted) _showError(context.read<RoomController>().error);
  }

  Future<void> _renameRoom(int id, String current) async {
    final name = await showRoomNameDialog(context, initialName: current);
    if (name == null || !mounted) return;
    final ok = await context.read<RoomController>().updateRoom(id, name);
    if (!ok && mounted) _showError(context.read<RoomController>().error);
  }

  Future<void> _deleteRoom(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Room',
            style: TextStyle(
                color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "$name"?\nThis cannot be undone.',
          style: const TextStyle(
              color: AppTheme.onSurfaceSub, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.onSurfaceSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    final ok = await context.read<RoomController>().deleteRoom(id);
    if (!ok && mounted) _showError(context.read<RoomController>().error);
  }

  void _showError(String? msg) {
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoomController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rooms',
                      style: TextStyle(
                        color: AppTheme.onBackground,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _createRoom,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.plus,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: ctrl.loading && ctrl.rooms.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : ctrl.rooms.isEmpty
                      ? _EmptyState(onAdd: _createRoom)
                      : RefreshIndicator(
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceCard,
                          onRefresh: ctrl.fetchRooms,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                16, 8, 16, 32),
                            itemCount: ctrl.rooms.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final room = ctrl.rooms[i];
                              return RoomCard(
                                room: room,
                                onTap:    () => _openRoom(context, ctrl.rooms[i]),
                                onRename: () =>
                                    _renameRoom(room.id, room.name),
                                onDelete: () =>
                                    _deleteRoom(room.id, room.name),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }


  void _openRoom(BuildContext context, RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailScreen(room: room),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(CupertinoIcons.house_fill,
                  color: AppTheme.onSurfaceSub, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Rooms Yet',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to create your first room.',
              style: TextStyle(
                  color: AppTheme.onSurfaceSub, fontSize: 14),
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(CupertinoIcons.plus, size: 16),
              label: const Text('Add Room'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ],
        ),
      );
}
