// lib/features/skeleton_stream/presentation/skeleton_stream_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:altum_view/features/skeleton_stream/service/models/skeleton_model.dart';
import 'package:altum_view/features/skeleton_stream/service/remote_service/skeleton_stream_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/features/skeleton_stream/controller/skeleton_stream_controller.dart';

enum StreamOrientation {
  landscape,
  portrait,
}

// ─────────────────────────────────────────────────────────────────────────────
// SkeletonStreamScreen
// ─────────────────────────────────────────────────────────────────────────────

class SkeletonStreamScreen extends StatelessWidget {
  final int cameraId;
  final String serialNumber;

  const SkeletonStreamScreen({
    super.key,
    required this.cameraId,
    required this.serialNumber,
  });

  @override
  Widget build(BuildContext context) {
    final client = context.read<DioClient>();

    return ChangeNotifierProvider(
      create: (_) => SkeletonStreamController(
        SkeletonStreamService(
          client: client,
          cameraId: cameraId,
          serialNumber: serialNumber,
        ),
      )..startStream(),
      child: const _SkeletonPage(),
    );
  }
}

class _SkeletonPage extends StatelessWidget {
  const _SkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<SkeletonStreamController>(
      builder: (_, controller, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Live View',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Icon(CupertinoIcons.xmark, color: AppTheme.primary),
            ),
            actions: [
              CupertinoButton(
                padding: const EdgeInsets.only(right: 12),
                onPressed: () async {
                  if (controller.isStreaming) {
                    await controller.stopStream();
                  } else {
                    await controller.startStream();
                  }
                },
                child: Icon(
                  controller.isStreaming
                      ? CupertinoIcons.stop_circle
                      : CupertinoIcons.play_circle,
                  size: 28,
                  color: controller.isStreaming ? AppTheme.error : AppTheme.success,
                ),
              ),
            ],
          ),
          body: const _StreamCanvas(
            orientation: StreamOrientation.landscape,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StreamCanvas
// ─────────────────────────────────────────────────────────────────────────────

class _StreamCanvas extends StatefulWidget {
  final StreamOrientation orientation;

  const _StreamCanvas({required this.orientation});

  @override
  State<_StreamCanvas> createState() => _StreamCanvasState();
}

class _StreamCanvasState extends State<_StreamCanvas> {
  // Always store as landscape: _nativeW >= _nativeH
  int? _nativeW;
  int? _nativeH;

  @override
  void dispose() {
    // Do NOT call controller.stopStream() here.
    // The ChangeNotifierProvider above us owns the controller lifetime and will
    // call controller.dispose() → _service.stop() automatically when the route
    // is popped.  Calling stopStream() here races with that disposal and causes
    // "used after dispose" + SocketException errors.
    super.dispose();
  }

  // Uses dart:ui directly — gives raw JPEG pixel dimensions.
  Future<void> _decodeImageSize(Uint8List bytes) async {
    if (_nativeW != null) return;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      if (!mounted || w <= 0 || h <= 0) return;
      setState(() {
        // Ensure we always store longer side as _nativeW (landscape orientation)
        if (w >= h) {
          _nativeW = w;
          _nativeH = h;
        } else {
          _nativeW = h;
          _nativeH = w;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SkeletonStreamController>(
      builder: (_, controller, __) {
        // ── Loading ──────────────────────────────────────────────────────────
        if (controller.loading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                SizedBox(height: 16),
                Text(
                  'Connecting to stream…',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // ── Error ────────────────────────────────────────────────────────────
        if (controller.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final bg = controller.backgroundImage;

        if (bg != null && _nativeW == null) {
          _decodeImageSize(bg);
        }

        return LayoutBuilder(
          builder: (_, constraints) {
            final screenW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
            return _buildCanvas(controller, screenW);
          },
        );
      },
    );
  }

  Widget _buildCanvas(SkeletonStreamController controller, double screenW) {
    final isLandscape = widget.orientation == StreamOrientation.landscape;
    final bg = controller.backgroundImage;

    // ── Aspect ratio ──────────────────────────────────────────────────────────
    // _nativeW >= _nativeH (always stored as landscape raw JPEG dims).
    //
    // PORTRAIT  — show JPEG as-is (no rotation needed):
    //   box is short/landscape-shaped: H = screenW * (nativeH / nativeW)
    //   e.g. 1920×1080 → H = screenW * 0.5625
    //
    // LANDSCAPE — rotate JPEG +90° CW so the scene stands upright:
    //   after rotation displayed dims swap: W_disp=nativeH, H_disp=nativeW
    //   H_box = screenW * (nativeW / nativeH)
    //   e.g. 1920×1080 → H = screenW * 1.7778 (tall portrait box)

    final double nW = (_nativeW ?? 1920).toDouble();
    final double nH = (_nativeH ?? 1080).toDouble();

    final double renderedH = isLandscape
        ? screenW * (nW / nH)  // tall box for rotated landscape scene
        : screenW * (nH / nW); // short box for as-is landscape JPEG

    final imageStack = SizedBox(
      width: screenW,
      height: renderedH,
      child: ClipRect(
        child: Stack(
          children: [
            // ── Background ──────────────────────────────────────────────────
            Positioned.fill(
              child: bg != null
                  ? _Background(imageBytes: bg, isLandscape: isLandscape)
                  : const ColoredBox(color: Color(0xFF111111)),
            ),

            // ── Skeleton overlay ────────────────────────────────────────────
            if (controller.latestFrame != null &&
                controller.latestFrame!.persons.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkeletonPainter(
                    frame: controller.latestFrame!,
                    isLandscape: isLandscape,
                  ),
                ),
              ),

            // ── Status badge ────────────────────────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              child: _StatusBadge(status: controller.streamStatus),
            ),
          ],
        ),
      ),
    );

    // ── Person count HUD ──────────────────────────────────────────────────────
    final hud = Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.all(14),
      child: Text(
        '${controller.latestFrame?.persons.length ?? 0} Persons',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [imageStack, hud],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Background
//
// PORTRAIT  — raw JPEG is landscape; show as-is with BoxFit.fill.
//             Flutter's Image.memory handles EXIF internally for display.
//
// LANDSCAPE — rotate +90° CW using RotatedBox so the landscape scene
//             stands upright. RotatedBox participates in layout (unlike
//             Transform.rotate), so it reports swapped W↔H to the parent
//             and the image fills the box with zero overflow/clipping.
// ─────────────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  final Uint8List imageBytes;
  final bool isLandscape;

  const _Background({required this.imageBytes, required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    if (!isLandscape) {
      return Image.memory(
        imageBytes,
        fit: BoxFit.fill,
        gaplessPlayback: true,
      );
    }

    // RotatedBox(quarterTurns: 1) = +90° CW
    return RotatedBox(
      quarterTurns: 1,
      child: Image.memory(
        imageBytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.fill,
        gaplessPlayback: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final StreamStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text = 'Idle';
    Color color = Colors.grey;

    switch (status) {
      case StreamStatus.live:
        text = 'LIVE';
        color = Colors.red;
        break;
      case StreamStatus.connecting:
        text = 'Connecting';
        color = Colors.blue;
        break;
      case StreamStatus.waitingForFrame:
        text = 'Waiting';
        color = Colors.orange;
        break;
      case StreamStatus.republishing:
        text = 'Reconnect';
        color = Colors.purple;
        break;
      case StreamStatus.offline:
        text = 'Offline';
        color = Colors.grey;
        break;
      case StreamStatus.error:
        text = 'Error';
        color = Colors.red;
        break;
      case StreamStatus.idle:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SkeletonPainter
//
// Camera joint coords: x,y ∈ [0,1]
//
// PORTRAIT (no image rotation):
//   displayX = joint.x * W
//   displayY = joint.y * H
//
// LANDSCAPE (+90° CW image rotation):
//   +90° CW maps:  camera +X (right) → screen +Y (down)
//                  camera +Y (down)  → screen -X (left)
//   displayX = (1.0 - joint.y) * W
//   displayY =        joint.x  * H
// ─────────────────────────────────────────────────────────────────────────────

const List<List<int>> _kBones = [
  [0, 1],
  [1, 2], [1, 5],
  [2, 3], [3, 4],
  [5, 6], [6, 7],
  [1, 8], [1, 11],
  [8, 9], [9, 10],
  [11, 12], [12, 13],
  [0, 14], [0, 15],
  [14, 16], [15, 17],
];

const List<Color> _kPersonColors = [
  Color(0xFF00FFCC),
  Color(0xFFFF6B9D),
  Color(0xFFFFD700),
  Color(0xFF4A9EFF),
];

class _SkeletonPainter extends CustomPainter {
  final SkeletonFrame frame;
  final bool isLandscape;

  const _SkeletonPainter({required this.frame, required this.isLandscape});

  Offset _toDisplay(SkeletonJoint j, Size size) {
    if (isLandscape) {
      return Offset(
        (1.0 - j.y) * size.width,
        j.x * size.height,
      );
    }
    return Offset(
      j.x * size.width,
      j.y * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int pi = 0; pi < frame.persons.length; pi++) {
      final joints = frame.persons[pi];
      final color = _kPersonColors[pi % _kPersonColors.length];

      // Draw bones
      for (final bone in _kBones) {
        final ai = bone[0], bi = bone[1];
        if (ai >= joints.length || bi >= joints.length) continue;
        final ja = joints[ai], jb = joints[bi];
        // Skip zeroed-out joints (undetected keypoints)
        if (ja.x == 0.0 && ja.y == 0.0) continue;
        if (jb.x == 0.0 && jb.y == 0.0) continue;

        canvas.drawLine(
          _toDisplay(ja, size),
          _toDisplay(jb, size),
          Paint()
            ..color = color.withOpacity(0.9)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }

      // Draw joints
      for (final j in joints) {
        if (j.x == 0.0 && j.y == 0.0) continue;
        final pt = _toDisplay(j, size);
        canvas.drawCircle(pt, 6.0, Paint()..color = color.withOpacity(0.15));
        canvas.drawCircle(pt, 3.5, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter old) =>
      old.frame != frame || old.isLandscape != isLandscape;
}