import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double borderRadius;
  final List<BoxShadow>? shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius = 24.0,
    this.shadow,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) {
        HapticService.light();
        setState(() => _isPressed = true);
      },
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: widget.color ?? (isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: widget.shadow ?? [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.04),
              blurRadius: _isPressed ? 10 : 30,
              offset: Offset(0, _isPressed ? 4 : 15),
              spreadRadius: isDark ? 1 : -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(20),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
