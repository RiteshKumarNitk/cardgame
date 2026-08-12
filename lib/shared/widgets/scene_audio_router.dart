import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../services/audio_scene_mapper.dart';
import '../../services/audio_service.dart';

/// Watches the app router and switches the background-music scene as the
/// player navigates, so every screen's ambience is driven purely by route
/// (see [AudioSceneMapper]). Lives at the app root — no page needs to opt
/// in, and music flows continuously across transitions.
class SceneAudioRouter extends StatefulWidget {
  const SceneAudioRouter({super.key, required this.child});

  final Widget child;

  @override
  State<SceneAudioRouter> createState() => _SceneAudioRouterState();
}

class _SceneAudioRouterState extends State<SceneAudioRouter> {
  @override
  void initState() {
    super.initState();
    appRouter.routeInformationProvider.addListener(_syncScene);
    _syncScene();
  }

  @override
  void dispose() {
    appRouter.routeInformationProvider.removeListener(_syncScene);
    super.dispose();
  }

  void _syncScene() {
    final uri = appRouter.routeInformationProvider.value.uri;
    final scene = AudioSceneMapper.sceneForPath(uri.path);
    if (scene != null) {
      AudioService().setScene(scene);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
