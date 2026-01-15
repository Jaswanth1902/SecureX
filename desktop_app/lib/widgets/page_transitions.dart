import 'package:flutter/material.dart';

PageRoute<T> buildFadeSlideRoute<T>(Widget page, {Duration? duration}) {
  final transitionDuration = duration ?? const Duration(milliseconds: 320);
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0.02, 0.0),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
