import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:king011_icons/king011_icons.dart';

class Spin extends StatefulWidget {
  const Spin({
    Key? key,
    this.child,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);
  final Widget? child;
  final Duration duration;
  @override
  _SpinState createState() => _SpinState();
}

class _SpinState extends State<Spin> with SingleTickerProviderStateMixin {
  AnimationController? controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    _animation();
  }

  _animation() {
    if (controller != null) {
      return;
    }
    controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    animation = Tween(begin: 0.0, end: math.pi * 2).animate(controller!);

    controller!.repeat();
  }

  @override
  dispose() {
    if (controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.rotate(
          angle: animation.value,
          child: child,
        ),
        child: widget.child ??
            const FloatingActionButton(
              child: Spin(
                child: Icon(
                  FontAwesome.spinner,
                  size: 32,
                ),
              ),
              onPressed: null,
            ),
      );
}
