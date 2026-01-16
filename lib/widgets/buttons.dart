import 'package:flutter/material.dart';
import 'animations.dart';

// Enhanced Buttons - Phase 2 UI Enhancement
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Duration animationDuration;
  final double scaleFactor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final bool enabled;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.animationDuration = AppAnimations.quick,
    this.scaleFactor = AppAnimations.tapScale,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.border,
    this.enabled = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled && widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : AppAnimations.disabledOpacity,
              child: Container(
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? theme.colorScheme.primary,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  border: widget.border,
                  boxShadow: widget.enabled && widget.onPressed != null
                      ? [
                          BoxShadow(
                            color: (widget.backgroundColor ?? theme.colorScheme.primary).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Enhanced Elevated Button
class EnhancedElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isLoading;
  final String? loadingText;

  const EnhancedElevatedButton({
    super.key,
    this.onPressed,
    required this.child,
    this.style,
    this.isLoading = false,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: AnimatedSwitcher(
        duration: AppAnimations.quick,
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  if (loadingText != null) ...[
                    const SizedBox(width: 8),
                    Text(loadingText!),
                  ],
                ],
              )
            : child,
      ),
    );
  }
}

// Animated Icon Button
class AnimatedIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? color;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const AnimatedIconButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
    this.iconSize,
    this.padding,
    this.enabled = true,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.quick,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.bounceOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: AppAnimations.tapScale).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enabled && widget.onPressed != null) {
      _controller.forward().then((_) => _controller.reverse());
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : AppAnimations.disabledOpacity,
              child: IconButton(
                onPressed: widget.enabled ? _handleTap : null,
                icon: Icon(widget.icon),
                tooltip: widget.tooltip,
                color: widget.color,
                iconSize: widget.iconSize,
                padding: widget.padding,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Floating Action Button with Animation
class AnimatedFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;
  final bool isExtended;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedFab({
    super.key,
    this.onPressed,
    this.child,
    this.tooltip,
    this.isExtended = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: AppAnimations.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      _controller.forward().then((_) => _controller.reverse());
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _handleTap,
              label: widget.child ?? const Icon(Icons.add),
              icon: const Icon(Icons.add),
              tooltip: widget.tooltip,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              isExtended: widget.isExtended,
            ),
          ),
        );
      },
    );
  }
}

// Ripple Button Effect
class RippleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? rippleColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const RippleButton({
    super.key,
    this.onPressed,
    required this.child,
    this.rippleColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        splashColor: rippleColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.1),
        highlightColor: rippleColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: padding ?? const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}

// Toggle Button with Animation
class AnimatedToggleButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback? onPressed;
  final Widget selectedChild;
  final Widget unselectedChild;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Duration animationDuration;

  const AnimatedToggleButton({
    super.key,
    required this.isSelected,
    this.onPressed,
    required this.selectedChild,
    required this.unselectedChild,
    this.selectedColor,
    this.unselectedColor,
    this.animationDuration = AppAnimations.normal,
  });

  @override
  State<AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<AnimatedToggleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: widget.unselectedColor ?? Colors.grey[300],
      end: widget.selectedColor ?? Theme.of(context).colorScheme.primary,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.bounceOut),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedSwitcher(
                    duration: widget.animationDuration,
                    child: widget.isSelected ? widget.selectedChild : widget.unselectedChild,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
