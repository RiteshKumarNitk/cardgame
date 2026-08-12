// Verifies route paths resolve to the right ambience scenes, including
// template params and the 'keep current scene' default.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/services/audio_manifest.dart';
import 'package:puzzle_cards/services/audio_scene_mapper.dart';

void main() {
  test('maps hub and gameplay routes to scenes', () {
    expect(AudioSceneMapper.sceneForPath('/'), AudioScene.home);
    expect(AudioSceneMapper.sceneForPath('/home'), AudioScene.home);
    expect(AudioSceneMapper.sceneForPath('/levels'), AudioScene.levels);
    expect(AudioSceneMapper.sceneForPath('/collections'), AudioScene.levels);
    expect(AudioSceneMapper.sceneForPath('/puzzle/12'), AudioScene.puzzle);
    expect(AudioSceneMapper.sceneForPath('/daily-puzzle'), AudioScene.puzzle);
    expect(AudioSceneMapper.sceneForPath('/photo-puzzles'), AudioScene.puzzle);
    expect(AudioSceneMapper.sceneForPath('/photo-puzzle'), AudioScene.puzzle);
    expect(AudioSceneMapper.sceneForPath('/shop'), AudioScene.shop);
    expect(AudioSceneMapper.sceneForPath('/cosmetics/frames'), AudioScene.shop);
    expect(AudioSceneMapper.sceneForPath('/gallery'), AudioScene.gallery);
    expect(AudioSceneMapper.sceneForPath('/victory'), AudioScene.victory);
    expect(
      AudioSceneMapper.sceneForPath('/chapter-complete'),
      AudioScene.victory,
    );
    expect(
      AudioSceneMapper.sceneForPath('/section-complete'),
      AudioScene.victory,
    );
  });

  test('transient screens keep whatever is playing', () {
    expect(AudioSceneMapper.sceneForPath('/settings'), isNull);
    expect(AudioSceneMapper.sceneForPath('/profile'), isNull);
    expect(AudioSceneMapper.sceneForPath('/leaderboard'), isNull);
    expect(AudioSceneMapper.sceneForPath('/unknown'), isNull);
  });
}
