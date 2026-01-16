import 'package:flutter/material.dart';

// Animation Constants - Phase 2 UI Enhancement
class AppAnimations {
  // Duration Constants
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);

  // Curve Constants
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;

  // Custom Curves for specific effects
  static const Curve smooth = Curves.fastOutSlowIn;
  static const Curve sharp = Curves.fastLinearToSlowEaseIn;
  static const Curve gentle = Curves.easeOutCubic;

  // Stagger delays for sequential animations
  static Duration stagger(int index, {Duration base = micro}) {
    return base * index;
  }

  // Scale factors for tap animations
  static const double tapScale = 0.95;
  static const double hoverScale = 1.02;
  static const double pressScale = 0.92;

  // Opacity values for states
  static const double disabledOpacity = 0.5;
  static const double hoverOpacity = 0.8;
  static const double focusOpacity = 0.9;
}

// Page Transition Builders
class AppPageTransitions {
  static Map<TargetPlatform, PageTransitionsBuilder> slideUp() {
    return {
      TargetPlatform.android: const _SlideUpTransitionBuilder(),
      TargetPlatform.iOS: const _SlideUpTransitionBuilder(),
      TargetPlatform.windows: const _SlideUpTransitionBuilder(),
    };
  }

  static Map<TargetPlatform, PageTransitionsBuilder> fade() {
    return {
      TargetPlatform.android: const _FadeTransitionBuilder(),
      TargetPlatform.iOS: const _FadeTransitionBuilder(),
      TargetPlatform.windows: const _FadeTransitionBuilder(),
    };
  }

  static Map<TargetPlatform, PageTransitionsBuilder> scale() {
    return {
      TargetPlatform.android: const _ScaleTransitionBuilder(),
      TargetPlatform.iOS: const _ScaleTransitionBuilder(),
      TargetPlatform.windows: const _ScaleTransitionBuilder(),
    };
  }
}

// Custom Transition Builders
class _SlideUpTransitionBuilder extends PageTransitionsBuilder {
  const _SlideUpTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }
}

class _FadeTransitionBuilder extends PageTransitionsBuilder {
  const _FadeTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class _ScaleTransitionBuilder extends PageTransitionsBuilder {
  const _ScaleTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeOutBack;
    var scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).chain(CurveTween(curve: curve)).animate(animation);

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

// Animation Extensions
extension AnimationExtensions on AnimationController {
  // Smooth reset with custom duration
  Future<void> smoothReset({Duration? duration}) {
    return animateTo(0.0, duration: duration ?? AppAnimations.normal, curve: AppAnimations.easeOut);
  }

  // Smooth forward with custom duration
  Future<void> smoothForward({Duration? duration}) {
    return animateTo(1.0, duration: duration ?? AppAnimations.normal, curve: AppAnimations.easeOut);
  }

  // Bounce effect
  Future<void> bounce() async {
    await forward();
    await reverse();
  }
}

// Widget Animation Helpers
class AnimationUtils {
  // Create a staggered animation for multiple widgets
  static List<Animation<double>> createStaggeredAnimations(
    AnimationController controller,
    int count, {
    Duration staggerDelay = AppAnimations.micro,
    Duration totalDuration = AppAnimations.slow,
  }) {
    final animations = <Animation<double>>[];

    for (int i = 0; i < count; i++) {
      final startTime = i * staggerDelay.inMilliseconds / totalDuration.inMilliseconds;
      final endTime = (i + 1) * staggerDelay.inMilliseconds / totalDuration.inMilliseconds;

      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(startTime.clamp(0.0, 1.0), endTime.clamp(0.0, 1.0), curve: AppAnimations.smooth),
        ),
      );

      animations.add(animation);
    }

    return animations;
  }

  // Create a breathing animation (subtle scale)
  static Animation<double> createBreathingAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: controller, curve: AppAnimations.gentle),
    );
  }

  // Create a pulse animation
  static Animation<double> createPulseAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: controller, curve: AppAnimations.bounceOut),
    );
  }
}
