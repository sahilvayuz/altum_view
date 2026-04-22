// features/cameras/controller/camera_controller.dart

import 'package:altum_view/features/camera/service/models/camera_model.dart';
import 'package:altum_view/features/camera/service/remote_service/camera_service.dart';
import 'package:flutter/foundation.dart';

enum CameraLoadStatus { idle, loading, success, error }

class CameraController extends ChangeNotifier {
  final CameraService _service;
  CameraController(this._service);

  List<CameraModel> cameras   = [];
  CameraLoadStatus  status    = CameraLoadStatus.idle;
  String?           errorMessage;

  Future<void> fetchCameras(int roomId) async {
    status = CameraLoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      cameras = await _service.getCamerasForRoom(roomId);
      status  = CameraLoadStatus.success;
    } catch (e) {
      status       = CameraLoadStatus.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> refresh(int roomId) => fetchCameras(roomId);
}