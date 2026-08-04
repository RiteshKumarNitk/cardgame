import 'package:flutter/material.dart';

import '../../core/design_system/app_animations.dart';
import '../../services/audio_service.dart';

/// Wraps [child] so it scales down slightly while pressed and springs back
/// on release, then fires [onTap]. Shared by every tappable card/button so
/// press feedback is consistent across the app.
///
/// Also plays the shared tap SFX on tap and a hover SFX when a mouse
/// pointer enters (desktop/web only — touch has no hover).
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = AppAnimations.pressedScale,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => AudioService().playButtonHover(),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          AudioService().playTap();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1.0,
          duration: AppAnimations.fast,
          curve: AppAnimations.pressCurve,
          child: widget.child,
        ),
      ),
    );
  }
}
