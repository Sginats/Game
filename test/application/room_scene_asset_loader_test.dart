import 'dart:io';

import 'package:ai_evolution/application/services/room_scene_asset_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _LocalFileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('room scene asset loader returns all 20 authored room configs', () async {
    const loader = RoomSceneAssetLoader();
    final bundle = _LocalFileAssetBundle();

    final rooms = await loader.loadAll(bundle: bundle);

    expect(rooms, hasLength(20));
    expect(rooms.first['id'], 'room_01');
    expect(rooms.last['id'], 'room_20');
    expect(
      rooms.every((room) => room['eventPool'] != null),
      isTrue,
    );
    expect(
      rooms.every(
        (room) => (room['transformationStages'] as List<dynamic>).length == 5,
      ),
      isTrue,
    );
    expect(
      rooms.every((room) => room['roomLaw'] != null),
      isTrue,
      reason: 'All rooms should have a roomLaw defined',
    );
    expect(
      rooms.every((room) => room['landmark'] != null),
      isTrue,
      reason: 'All rooms should have a landmark defined',
    );
    expect(
      rooms.every((room) => room['hazard'] != null),
      isTrue,
      reason: 'All rooms should have a hazard defined',
    );
    expect(
      rooms.every((room) => room['stabilizer'] != null),
      isTrue,
      reason: 'All rooms should have a stabilizer defined',
    );
    expect(
      rooms.every((room) => room['completionCeremony'] != null),
      isTrue,
      reason: 'All rooms should have a completionCeremony defined',
    );
  });
}
