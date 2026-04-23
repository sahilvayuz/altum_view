class RoomModel {
  final int id;
  final String name;
  final int cameraCount;
  final int weakWifiStrengthCount;
  final int onlineCameraCount;
  final int backgroundType;
  final bool favouriteRoom;

  const RoomModel({
    required this.id,
    required this.name,
    this.cameraCount = 0,
    this.weakWifiStrengthCount = 0,
    this.onlineCameraCount = 0,
    this.backgroundType = 0,
    this.favouriteRoom = false,
  });

  factory RoomModel.fromJson(Map<String, dynamic> j) {
    return RoomModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: j['friendly_name'] as String? ??
          j['name'] as String? ??
          'Unnamed Room',
      cameraCount: (j['camera_count'] as num?)?.toInt() ?? 0,
      weakWifiStrengthCount:
      (j['weak_wifi_strength_count'] as num?)?.toInt() ?? 0,
      onlineCameraCount:
      (j['online_camera_count'] as num?)?.toInt() ?? 0,
      backgroundType: (j['background_type'] as num?)?.toInt() ?? 0,
      favouriteRoom: (j['favourite_room'] as num?)?.toInt() == 1,
    );
  }

  RoomModel copyWith({
    String? name,
    int? cameraCount,
    int? weakWifiStrengthCount,
    int? onlineCameraCount,
    int? backgroundType,
    bool? favouriteRoom,
  }) {
    return RoomModel(
      id: id,
      name: name ?? this.name,
      cameraCount: cameraCount ?? this.cameraCount,
      weakWifiStrengthCount:
      weakWifiStrengthCount ?? this.weakWifiStrengthCount,
      onlineCameraCount:
      onlineCameraCount ?? this.onlineCameraCount,
      backgroundType: backgroundType ?? this.backgroundType,
      favouriteRoom: favouriteRoom ?? this.favouriteRoom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendly_name': name,
      'camera_count': cameraCount,
      'weak_wifi_strength_count': weakWifiStrengthCount,
      'online_camera_count': onlineCameraCount,
      'background_type': backgroundType,
      'favourite_room': favouriteRoom ? 1 : 0,
    };
  }
}