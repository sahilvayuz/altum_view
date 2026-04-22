// lib/features/skeleton_stream/controller/skeleton_stream_controller.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:altum_view/features/skeleton_stream/service/models/skeleton_model.dart';
import 'package:altum_view/features/skeleton_stream/service/remote_service/skeleton_stream_service.dart';
import 'package:flutter/foundation.dart';


class SkeletonStreamController extends ChangeNotifier {
  SkeletonStreamController(this._service);

  final SkeletonStreamService _service;

  SkeletonFrame? _latestFrame;
  Uint8List? _backgroundImage;

  StreamStatus _streamStatus = StreamStatus.idle;

  bool _loading = false;
  String? _error;

  // Tracks whether dispose() has been called so that async callbacks
  // that fire after disposal never call notifyListeners() on a dead object.
  bool _disposed = false;

  StreamSubscription<SkeletonFrame>? _frameSub;
  StreamSubscription<StreamStatus>? _statusSub;

  /// GETTERS

  SkeletonFrame? get latestFrame => _latestFrame;
  Uint8List? get backgroundImage => _backgroundImage;
  StreamStatus get streamStatus => _streamStatus;
  bool get loading => _loading;
  String? get error => _error;

  bool get isStreaming =>
      _streamStatus != StreamStatus.idle &&
          _streamStatus != StreamStatus.error;

  /// START STREAM

  Future<void> startStream() async {
    if (_loading || _disposed) return;

    _setLoading(true);

    try {
      _statusSub = _service.statusStream.listen(
            (status) {
          if (_disposed) return;
          _streamStatus = status;
          notifyListeners();
        },
      );

      await _service.start();

      if (_disposed) return;

      _backgroundImage = _service.backgroundImage;

      _frameSub = _service.skeletonFrames.listen(
            (frame) {
          if (_disposed) return;
          _latestFrame = frame;
          notifyListeners();
        },
        onError: (e) {
          if (_disposed) return;
          _error = e.toString();
          notifyListeners();
        },
      );

      _error = null;
      _setLoading(false);
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
      _setLoading(false);
    }
  }

  /// STOP STREAM

  Future<void> stopStream() async {
    await _frameSub?.cancel();
    await _statusSub?.cancel();

    _frameSub = null;
    _statusSub = null;

    await _service.stop();

    _latestFrame = null;
    _streamStatus = StreamStatus.idle;

    // Guard: Provider may have already called dispose() before this completes.
    if (!_disposed) notifyListeners();
  }

  /// DISPOSE

  @override
  void dispose() {
    _disposed = true;
    _frameSub?.cancel();
    _statusSub?.cancel();
    _service.stop();
    _service.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _loading = value;
    notifyListeners();
  }
}