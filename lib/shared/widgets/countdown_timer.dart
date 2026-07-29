import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a live `HH:MM:SS` countdown to [target], ticking every second
/// until it reaches zero. Used for "come back tomorrow" style resets.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.target, this.style});

  final DateTime target;
  final TextStyle? style;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _timeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining = _timeLeft());
    });
  }

  Duration _timeLeft() {
    final diff = widget.target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$hours:$minutes:$seconds', style: widget.style);
  }
}
