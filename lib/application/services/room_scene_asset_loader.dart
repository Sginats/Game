import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads room-scene JSON assets from the bundled config set.
class RoomSceneAssetLoader {
  static const List<String> roomAssetPaths = [
    'assets/config/rooms/room_01.json',
    'assets/config/rooms/room_02.json',
    'assets/config/rooms/room_03.json',
    'assets/config/rooms/room_04.json',
    'assets/config/rooms/room_05.json',
    'assets/config/rooms/room_06.json',
    'assets/config/rooms/room_07.json',
    'assets/config/rooms/room_08.json',
    'assets/config/rooms/room_09.json',
    'assets/config/rooms/room_10.json',
    'assets/config/rooms/room_11.json',
    'assets/config/rooms/room_12.json',
    'assets/config/rooms/room_13.json',
    'assets/config/rooms/room_14.json',
    'assets/config/rooms/room_15.json',
    'assets/config/rooms/room_16.json',
    'assets/config/rooms/room_17.json',
    'assets/config/rooms/room_18.json',
    'assets/config/rooms/room_19.json',
    'assets/config/rooms/room_20.json',
  ];

  const RoomSceneAssetLoader();

  Future<List<Map<String, dynamic>>> loadAll({
    AssetBundle? bundle,
  }) async {
    final assetBundle = bundle ?? rootBundle;
    final rooms = <Map<String, dynamic>>[];
    for (final path in roomAssetPaths) {
      final raw = await assetBundle.loadString(path);
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        rooms.add(decoded);
      }
    }
    return rooms;
  }
}
