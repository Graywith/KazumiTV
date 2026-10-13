import 'package:flutter/material.dart';
import 'package:kazumi/bean/tv/tv_support.dart';

class TvActionFocus extends StatefulWidget {
  const TvActionFocus({super.key, required this.child});
  final Widget child;

  @override
  State<TvActionFocus> createState() => _TvActionFocusState();
}

class _TvActionFocusState extends State<TvActionFocus> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    if (!isTv) return widget.child;
    return Focus(
      canRequestFocus: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: AnimatedScale(
        scale: _focused ? 1.05 : 1,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
