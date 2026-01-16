import 'package:flutter/material.dart';

class StaggeredAnim extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;
  final double slideOffset;
  final Duration? delay;

  const StaggeredAnim({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
    this.slideOffset = 50.0,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    // Each item starts 50ms after the previous one
    final Duration staggerDelay = delay ?? Duration(milliseconds: 50 * index);
    final Duration duration = const Duration(milliseconds: 600);
    
    // Calculate interval ensuring we don't exceed 1.0
    // We use a simple SlideTransition + FadeTransition driven by a CurvedAnimation
    // but delayed by the index.
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double animationValue = controller.value;
        // Simple logic: if animation hasn't reached our "start time", we are hidden.
        // But Controller goes 0 to 1.
        // Let's use SlideTransition with individual Animations created in InitState?
        // No, to make it reusable without complex orchestration, we can use an internal
        // Interval calculation based on the controller.
        
        // However, standard staggered animations usually pre-calculate the Intervals.
        // Let's try a simpler approach: AnimatedSlide/Opacity with a delay? 
        // No, that requires starting them individually.
        
        // Robust approach: Use Interval.
        // Assume total animation takes e.g. 1-2 seconds.
        // Item 1: 0.0 - 0.4
        // Item 2: 0.1 - 0.5
        // ...
        
        final double totalSteps = 10.0; // Assume max 10 items for simplicity
        final double step = 0.5 / totalSteps; // Overlap factor
        final double start = (index * step).clamp(0.0, 1.0);
        final double end = (start + 0.5).clamp(0.0, 1.0); // Each item takes half the controller duration
        
        final curve = CurvedAnimation(
          parent: controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.2), // Slight slide up
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
