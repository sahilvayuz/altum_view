class RoomModel {
  final int    id;
  final String name;
  final int    cameraCount;

  const RoomModel({
    required this.id,
    required this.name,
    this.cameraCount = 0,
  });

  factory RoomModel.fromJson(Map<String, dynamic> j) => RoomModel(
        id:          j['id'] as int,
        name:        j['name'] as String? ?? 'Unnamed Room',
        cameraCount: j['camera_count'] as int? ?? 0,
      );

  RoomModel copyWith({String? name}) =>
      RoomModel(id: id, name: name ?? this.name, cameraCount: cameraCount);
}
