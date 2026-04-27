// core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  static const String baseUrl  = 'https://api.altumview.ca/v1.0';
  static const String tokenUrl = 'https://oauth.altumview.ca/v1.0/token';

  // ── Auth / account ────────────────────────────────────────────────────────
  static const String info        = '/info';
  static const String mqttAccount = '/mqttAccount';

  // ── Rooms ─────────────────────────────────────────────────────────────────
  static const String rooms      = '/rooms';
  static String roomById(int id) => '/rooms/$id';

  // ── Cameras ───────────────────────────────────────────────────────────────
  static const String cameras                        = '/cameras';
  static String camerasBy(String sn)       => '/cameras?serial_number=$sn';
  static String cameraById(int id)                   => '/cameras/$id';
  static String cameraBackground(int id)             => '/cameras/$id/background';
  static String cameraStreamToken(int id)            => '/cameras/$id/streamtoken';
  static String bluetoothToken(String serialNumber)  =>
      '/cameras/bluetoothToken?serial_number=$serialNumber';
}