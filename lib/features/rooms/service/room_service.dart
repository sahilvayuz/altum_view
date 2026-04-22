import 'package:altum_view/core/constants/api_constants.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/features/rooms/service/room_model.dart';

class RoomService {
  const RoomService(this._client);

  final DioClient _client;

  Future<List<RoomModel>> getRooms() async {
    final resp = await _client.get(ApiConstants.rooms);
    final arr  = resp.data['data']?['rooms']?['array'] as List? ?? [];
    return arr.cast<Map<String, dynamic>>().map(RoomModel.fromJson).toList();
  }

  Future<RoomModel> createRoom(String name) async {
    final resp = await _client.post(ApiConstants.rooms, data: {'name': name});
    final json = resp.data['data']?['room'] as Map<String, dynamic>;
    return RoomModel.fromJson(json);
  }

  Future<void> updateRoom(int id, String name) =>
      _client.patch(ApiConstants.roomById(id), data: {'name': name});

  Future<void> deleteRoom(int id) => _client.delete(ApiConstants.roomById(id));
}
