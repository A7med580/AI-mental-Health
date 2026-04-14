import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Smooth iOS-style page transitions for the app.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // iOS-style slide from right + subtle fade
            final offsetTween = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic));

            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOutCubic));

            return SlideTransition(
              position: animation.drive(offsetTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Smooth crossfade transition for tab-like navigation (bottom nav).
class AppFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Gentle scale + fade for tab switches
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOutCubic));

            final scaleTween = Tween<double>(begin: 0.96, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOutCubic));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
        );
}

/// Helper to push with the proper transition type.
void navigateTo(BuildContext context, Widget page) {
  Navigator.push(context, AppPageRoute(page: page));
}

/// Replace current screen with a smooth fade (for bottom nav).
void switchTab(BuildContext context, Widget page) {
  Navigator.pushReplacement(context, AppFadeRoute(page: page));
}
