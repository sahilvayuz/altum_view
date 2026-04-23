// lib/features/skeleton_stream/presentation/skeleton_stream_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:altum_view/features/skeleton_stream/service/models/skeleton_model.dart';
import 'package:altum_view/features/skeleton_stream/service/remote_service/skeleton_stream_service.dart';
import 'package:altum_view/sdk_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:altum_view/features/skeleton_stream/controller/skeleton_stream_controller.dart';

enum StreamOrientation { landscape, portrait }

// ─────────────────────────────────────────────────────────────────────────────
// SkeletonStreamScreen — full-screen route (unchanged usage)
// ─────────────────────────────────────────────────────────────────────────────

class SkeletonStreamScreen extends StatelessWidget {
  final int    cameraId;
  final String serialNumber;

  const SkeletonStreamScreen({
    super.key,
    required this.cameraId,
    required this.serialNumber,
  });

  @override
  Widget build(BuildContext context) {
    final client = SDKClient.of(context);

    return ChangeNotifierProvider(
      create: (_) => SkeletonStreamController(
        SkeletonStreamService(
          client:       client,
          cameraId:     cameraId,
          serialNumber: serialNumber,
        ),
      )..startStream(),
      child: _SkeletonPage(
        cameraId:     cameraId,
        serialNumber: serialNumber,
      ),
    );
  }
}

class _SkeletonPage extends StatelessWidget {
  final int    cameraId;
  final String serialNumber;

  const _SkeletonPage({
    required this.cameraId,
    required this.serialNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SkeletonStreamController>(
      builder: (_, controller, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text('Live View',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            leading: CupertinoButton(
              padding:   EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Icon(CupertinoIcons.xmark, color: AppTheme.primary),
            ),
            actions: [
              /// pause and start stream button || right now causing issue
              // CupertinoButton(
              //   padding: const EdgeInsets.only(right: 12),
              //   onPressed: () async {
              //     if (controller.isStreaming) {
              //       await controller.stopStream();
              //     } else {
              //       await controller.startStream();
              //     }
              //   },
              //   child: Icon(
              //     controller.isStreaming
              //         ? CupertinoIcons.stop_circle
              //         : CupertinoIcons.play_circle,
              //     size:  28,
              //     color: controller.isStreaming
              //         ? AppTheme.error
              //         : AppTheme.success,
              //   ),
              // ),
            ],
          ),
          // Full-screen: fill available body width and height
          body: AltumStreamView(
            cameraId:            cameraId,
            serialNumber:        serialNumber,
            orientation:         StreamOrientation.landscape,
            useExternalProvider: true,   // provider already above us
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AltumStreamView — reusable embed widget
//
// Usage A — standalone (creates its own provider):
//   AltumStreamView(
//     cameraId:     camera.id,
//     serialNumber: camera.serialNumber,
//     orientation:  StreamOrientation.portrait,
//     width:        340,
//     height:       200,
//   )
//
// Usage B — inside SkeletonStreamScreen (provider already in tree):
//   AltumStreamView(
//     cameraId:            camera.id,
//     serialNumber:        camera.serialNumber,
//     orientation:         StreamOrientation.landscape,
//     useExternalProvider: true,
//   )
//
// When width/height are omitted the canvas expands to fill its parent
// (double.infinity × double.infinity), so you can wrap it in any
// SizedBox / Expanded / AspectRatio you like.
// ─────────────────────────────────────────────────────────────────────────────

class AltumStreamView extends StatelessWidget {
  final int               cameraId;
  final String            serialNumber;
  final StreamOrientation orientation;

  /// Explicit pixel width for the stream box.
  /// Defaults to double.infinity (fill parent width).
  final double width;

  /// Explicit pixel height for the stream box.
  /// When null the height is derived from the image aspect ratio automatically.
  final double? height;

  /// Set true when a [SkeletonStreamController] provider is already above
  /// this widget in the tree (e.g. inside [SkeletonStreamScreen]).
  final bool useExternalProvider;

  const AltumStreamView({
    super.key,
    required this.cameraId,
    required this.serialNumber,
    this.orientation         = StreamOrientation.landscape,
    this.width               = double.infinity,
    this.height,
    this.useExternalProvider = false,
  });

  @override
  Widget build(BuildContext context) {
    // SizedBox HERE gives _StreamCanvas finite constraints immediately.
    // LayoutBuilder inside _StreamCanvas then sees the correct maxWidth/maxHeight
    // instead of expanding to the parent's full size.
    final canvas = SizedBox(
      width:  width,
      height: height,
      child: _StreamCanvas(
        orientation: orientation,
        fixedWidth:  width,
        fixedHeight: height,
      ),
    );

    if (useExternalProvider) return canvas;

    final client = SDKClient.of(context);
    return ChangeNotifierProvider(
      create: (_) => SkeletonStreamController(
        SkeletonStreamService(
          client:       client,
          cameraId:     cameraId,
          serialNumber: serialNumber,
        ),
      )..startStream(),
      child: canvas,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StreamCanvas — internal stateful canvas
// ─────────────────────────────────────────────────────────────────────────────

class _StreamCanvas extends StatefulWidget {
  final StreamOrientation orientation;
  final double            fixedWidth;
  final double?           fixedHeight;

  const _StreamCanvas({
    required this.orientation,
    required this.fixedWidth,
    this.fixedHeight,
  });

  @override
  State<_StreamCanvas> createState() => _StreamCanvasState();
}

class _StreamCanvasState extends State<_StreamCanvas> {
  // Always stored as landscape dims: _nativeW >= _nativeH
  int? _nativeW;
  int? _nativeH;

  @override
  void dispose() {
    // Do NOT call controller.stopStream() here.
    // The ChangeNotifierProvider owns the controller lifetime and calls
    // controller.dispose() → _service.stop() automatically on route pop.
    super.dispose();
  }

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
        // Store longer side as _nativeW (landscape orientation)
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
        // ── Loading ────────────────────────────────────────────────────────
        if (controller.loading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2),
                SizedBox(height: 16),
                Text('Connecting to stream…',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          );
        }

        // ── Error ──────────────────────────────────────────────────────────
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
        if (bg != null && _nativeW == null) _decodeImageSize(bg);

        return LayoutBuilder(builder: (_, constraints) {
          // Resolve actual render width
          final resolvedW = widget.fixedWidth.isInfinite
              ? (constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width)
              : widget.fixedWidth;

          return _buildCanvas(controller, resolvedW);
        });
      },
    );
  }

  Widget _buildCanvas(SkeletonStreamController controller, double screenW) {
    final isLandscape = widget.orientation == StreamOrientation.landscape;
    final bg          = controller.backgroundImage;

    // ── Resolve render height ────────────────────────────────────────────────
    //
    // Priority:
    //   1. Caller-supplied fixedHeight (explicit sizing)
    //   2. Computed from image aspect ratio once decoded
    //   3. Fallback: 16:9 for landscape, 9:16 for portrait
    //
    // Stored dims: _nativeW >= _nativeH (raw landscape JPEG).
    //
    // PORTRAIT  — show as-is: H = W * (nativeH / nativeW)   ← short box
    // LANDSCAPE — rotate +90° CW: H = W * (nativeW / nativeH) ← tall box

    final double nW = (_nativeW ?? 1920).toDouble();
    final double nH = (_nativeH ?? 1080).toDouble();

    final double renderedH = widget.fixedHeight ??
        (isLandscape ? screenW * (nW / nH) : screenW * (nH / nW));

    final imageStack = SizedBox(
      width:  screenW,
      height: renderedH,
      child: ClipRect(
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: bg != null
                  ? _Background(imageBytes: bg, isLandscape: isLandscape)
                  : const ColoredBox(color: Color(0xFF111111)),
            ),

            // Skeleton overlay
            if (controller.latestFrame != null &&
                controller.latestFrame!.persons.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkeletonPainter(
                    frame:       controller.latestFrame!,
                    isLandscape: isLandscape,
                  ),
                ),
              ),

            // Status badge
            Positioned(
              top:  12,
              left: 12,
              child: _StatusBadge(status: controller.streamStatus),
            ),
          ],
        ),
      ),
    );

    // Person count HUD
    final hud = Container(
      width:   double.infinity,
      color:   Colors.black,
      padding: const EdgeInsets.all(14),
      child: Text(
        '${controller.latestFrame?.persons.length ?? 0} Persons',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   18,
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
// ─────────────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  final Uint8List imageBytes;
  final bool      isLandscape;

  const _Background({required this.imageBytes, required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    if (!isLandscape) {
      return Image.memory(
        imageBytes,
        fit:             BoxFit.fill,
        gaplessPlayback: true,
      );
    }

    // RotatedBox participates in layout → zero overflow, zero crop
    return RotatedBox(
      quarterTurns: 1, // +90° CW
      child: Image.memory(
        imageBytes,
        width:           double.infinity,
        height:          double.infinity,
        fit:             BoxFit.fill,
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
    final (text, color) = switch (status) {
      StreamStatus.live           => ('LIVE',       Colors.red),
      StreamStatus.connecting     => ('Connecting', Colors.blue),
      StreamStatus.waitingForFrame=> ('Waiting',    Colors.orange),
      StreamStatus.republishing   => ('Reconnect',  Colors.purple),
      StreamStatus.offline        => ('Offline',    Colors.grey),
      StreamStatus.error          => ('Error',      Colors.red),
      StreamStatus.idle           => ('Idle',       Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
            color:      color,
            fontSize:   12,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SkeletonPainter
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
  final bool          isLandscape;

  const _SkeletonPainter({required this.frame, required this.isLandscape});

  Offset _toDisplay(SkeletonJoint j, Size size) {
    if (isLandscape) {
      return Offset(
        (1.0 - j.y) * size.width,
        j.x          * size.height,
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
      final color  = _kPersonColors[pi % _kPersonColors.length];

      for (final bone in _kBones) {
        final ai = bone[0], bi = bone[1];
        if (ai >= joints.length || bi >= joints.length) continue;
        final ja = joints[ai], jb = joints[bi];
        if (ja.x == 0.0 && ja.y == 0.0) continue;
        if (jb.x == 0.0 && jb.y == 0.0) continue;

        canvas.drawLine(
          _toDisplay(ja, size),
          _toDisplay(jb, size),
          Paint()
            ..color       = color.withOpacity(0.9)
            ..strokeWidth = 2.5
            ..strokeCap   = StrokeCap.round
            ..style       = PaintingStyle.stroke,
        );
      }

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