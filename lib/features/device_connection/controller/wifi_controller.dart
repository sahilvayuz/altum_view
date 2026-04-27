// ============================================================
// wifi_controller.dart
// ============================================================

import 'package:altum_view/features/device_connection/service/wifi_service.dart';
import 'package:flutter/foundation.dart';

enum WifiChangeStep {
  idle,
  scanning,
  selecting,
  connecting,
  success,
  error,
}

class WifiController extends ChangeNotifier {
  WifiController(this._service);

  final WifiService _service;

  bool _disposed = false;

  // ── State ───────────────────────────────────────────────
  WifiChangeStep step = WifiChangeStep.idle;
  String statusMessage = '';
  List<String> networks = [];
  bool loading = false;
  String? error;

  // ── Load Networks ───────────────────────────────────────
  Future<void> loadNetworks() async {
    _setLoading(true);

    try {
      step = WifiChangeStep.scanning;
      _safeNotify();

      networks = await _service.getAvailableNetworks();

      step = WifiChangeStep.selecting;
      error = null;
    } catch (e) {
      step = WifiChangeStep.error;
      error = e.toString();
      statusMessage = e.toString();
    }

    _setLoading(false);
  }

  // ── Change Wifi ─────────────────────────────────────────
  Future<bool> changeWifi({
    required String token,
    required String ssid,
    required String password,
    required String mqttPasscode,
    required String groupId,
  }) async {
    _setLoading(true);

    try {
      step = WifiChangeStep.connecting;
      statusMessage = 'Disconnecting old network…';
      _safeNotify();

      await _service.disconnect(token);

      statusMessage = 'Setting server…';
      _safeNotify();

      await _service.setServer(token);

      statusMessage = 'Sending Wi-Fi credentials…';
      _safeNotify();

      final result = await _service.setWifi(
        token: token,
        ssid: ssid,
        password: password,
        mqttPasscode: mqttPasscode,
        groupId: groupId,
      );

      if (result['wifi_status'] == 'success') {
        step = WifiChangeStep.success;
        error = null;

        _setLoading(false);
        return true;
      }

      throw Exception('Wi-Fi failed');
    } catch (e) {
      step = WifiChangeStep.error;
      error = e.toString();
      statusMessage = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // ── Dispose Controller ──────────────────────────────────
  Future<void> disposeController() async {
    reset();
  }

  // ── Reset ───────────────────────────────────────────────
  void reset() {
    step = WifiChangeStep.idle;
    statusMessage = '';
    networks.clear();
    loading = false;
    error = null;

    _safeNotify();
  }

  // ── Helpers ─────────────────────────────────────────────
  void _setLoading(bool v) {
    loading = v;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}