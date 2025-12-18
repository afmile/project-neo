/// Project Neo - GOD MODE Detector
///
/// Secret 7-tap gesture to activate owner privileges.
library;

import 'package:flutter/material.dart';

/// Detects 7 rapid taps to activate GOD MODE
class GodModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onActivate;
  final int requiredTaps;
  final Duration timeout;
  
  const GodModeDetector({
    super.key,
    required this.child,
    required this.onActivate,
    this.requiredTaps = 7,
    this.timeout = const Duration(seconds: 3),
  });

  @override
  State<GodModeDetector> createState() => _GodModeDetectorState();
}

class _GodModeDetectorState extends State<GodModeDetector> {
  int _tapCount = 0;
  DateTime? _firstTapTime;
  
  void _handleTap() {
    final now = DateTime.now();
    
    // Reset if timeout exceeded
    if (_firstTapTime != null && now.difference(_firstTapTime!) > widget.timeout) {
      _tapCount = 0;
      _firstTapTime = null;
    }
    
    // Start counting
    _firstTapTime ??= now;
    _tapCount++;
    
    // Check if activated
    if (_tapCount >= widget.requiredTaps) {
      _tapCount = 0;
      _firstTapTime = null;
      widget.onActivate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
