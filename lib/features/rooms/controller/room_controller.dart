import 'package:altum_view/features/rooms/service/room_model.dart';
import 'package:altum_view/features/rooms/service/room_service.dart';
import 'package:flutter/foundation.dart';

class RoomController extends ChangeNotifier {
  RoomController(this._service);

  final RoomService _service;

  List<RoomModel> _rooms   = [];
  bool            _loading = false;
  String?         _error;

  List<RoomModel> get rooms   => _rooms;
  bool            get loading => _loading;
  String?         get error   => _error;

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> fetchRooms() async {
    _setLoading(true);
    try {
      _rooms = await _service.getRooms();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  // ── Create ─────────────────────────────────────────────────────────────────
  Future<bool> createRoom(String name) async {
    _setLoading(true);
    try {
      final room = await _service.createRoom(name);
      _rooms = [..._rooms, room];
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<bool> updateRoom(int id, String name) async {
    _setLoading(true);
    try {
      await _service.updateRoom(id, name);
      _rooms = _rooms.map((r) => r.id == id ? r.copyWith(name: name) : r).toList();
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<bool> deleteRoom(int id) async {
    _setLoading(true);
    try {
      await _service.deleteRoom(id);
      _rooms = _rooms.where((r) => r.id != id).toList();
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
