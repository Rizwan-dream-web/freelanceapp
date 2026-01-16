import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animations.dart';

// Enhanced Form Components - Phase 2 UI Enhancement
class AnimatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  final Color? fillColor;
  final BorderRadius? borderRadius;

  const AnimatedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.borderRadius,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderAnimation;
  late Animation<Color?> _labelColorAnimation;
  late Animation<Color?> _borderColorAnimation;

  FocusNode? _focusNode;
  bool _hasFocus = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.quick,
      vsync: this,
    );

    _borderAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );

    _focusNode = FocusNode();
    _focusNode!.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);

    _labelColorAnimation = ColorTween(
      begin: theme.colorScheme.onSurface.withOpacity(0.6),
      end: theme.colorScheme.primary,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );

    _borderColorAnimation = ColorTween(
      begin: theme.colorScheme.outline,
      end: theme.colorScheme.primary,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _hasFocus = _focusNode!.hasFocus;
    });

    if (_hasFocus) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.fillColor ?? theme.colorScheme.surface,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? theme.colorScheme.error
                      : _borderColorAnimation.value ?? theme.colorScheme.outline,
                  width: hasError ? 2.0 : _borderAnimation.value,
                ),
                boxShadow: _hasFocus && !hasError
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                textCapitalization: widget.textCapitalization,
                onTap: widget.onTap,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: TextStyle(
                  color: widget.enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  labelStyle: TextStyle(
                    color: hasError
                        ? theme.colorScheme.error
                        : _labelColorAnimation.value,
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  counterText: '',
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: hasError ? 1.0 : 0.0,
                duration: AppAnimations.quick,
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Enhanced Dropdown with Animation
class AnimatedDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool enabled;
  final Widget? prefixIcon;
  final Color? fillColor;
  final BorderRadius? borderRadius;

  const AnimatedDropdown({
    super.key,
    this.value,
    this.items,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.prefixIcon,
    this.fillColor,
    this.borderRadius,
  });

  @override
  State<AnimatedDropdown<T>> createState() => _AnimatedDropdownState<T>();
}

class _AnimatedDropdownState<T> extends State<AnimatedDropdown<T>> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderAnimation;
  late Animation<Color?> _borderColorAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.quick,
      vsync: this,
    );

    _borderAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);

    _borderColorAnimation = ColorTween(
      begin: theme.colorScheme.outline,
      end: theme.colorScheme.primary,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.fillColor ?? theme.colorScheme.surface,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? theme.colorScheme.error
                      : _borderColorAnimation.value ?? theme.colorScheme.outline,
                  width: hasError ? 2.0 : _borderAnimation.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<T>(
                value: widget.value,
                items: widget.items,
                onChanged: widget.enabled ? widget.onChanged : null,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: AppAnimations.quick,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                style: TextStyle(
                  color: widget.enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                dropdownColor: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => _isExpanded = true);
                  _controller.forward();
                },
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: hasError ? 1.0 : 0.0,
                duration: AppAnimations.quick,
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Animated Error Dialog
class AnimatedErrorDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? details;
  final List<Widget>? actions;
  final IconData icon;
  final Color? iconColor;

  const AnimatedErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.actions,
    this.icon = Icons.error_outline,
    this.iconColor,
  });

  @override
  State<AnimatedErrorDialog> createState() => _AnimatedErrorDialogState();
}

class _AnimatedErrorDialogState extends State<AnimatedErrorDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.iconColor ?? theme.colorScheme.error;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  AnimatedScale(
                    scale: 1.0,
                    duration: AppAnimations.normal,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: iconColor, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.message, style: theme.textTheme.bodyLarge),
                  if (widget.details != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.details!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: widget.actions ?? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: iconColor)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Animated Success Dialog
class AnimatedSuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final List<Widget>? actions;
  final VoidCallback? onDismiss;

  const AnimatedSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.actions,
    this.onDismiss,
  });

  @override
  State<AnimatedSuccessDialog> createState() => _AnimatedSuccessDialogState();
}

class _AnimatedSuccessDialogState extends State<AnimatedSuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  AnimatedScale(
                    scale: _checkAnimation.value,
                    duration: AppAnimations.normal,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle, color: Colors.green, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(widget.message, style: theme.textTheme.bodyLarge),
              actions: widget.actions ?? [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDismiss?.call();
                  },
                  child: const Text('OK', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Animated Switch
class AnimatedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final String? label;
  final TextStyle? labelStyle;

  const AnimatedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.label,
    this.labelStyle,
  });

  @override
  State<AnimatedSwitch> createState() => _AnimatedSwitchState();
}

class _AnimatedSwitchState extends State<AnimatedSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(bool value) {
    _controller.forward().then((_) => _controller.reverse());
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: widget.value,
                onChanged: _handleChanged,
                activeColor: widget.activeColor,
                activeTrackColor: widget.activeTrackColor,
                inactiveThumbColor: widget.inactiveThumbColor,
                inactiveTrackColor: widget.inactiveTrackColor,
              ),
              if (widget.label != null) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label!,
                  style: widget.labelStyle,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Form Field Container with Animation
class AnimatedFormField extends StatefulWidget {
  final Widget child;
  final String? label;
  final String? errorText;
  final bool hasFocus;
  final Duration animationDuration;

  const AnimatedFormField({
    super.key,
    required this.child,
    this.label,
    this.errorText,
    this.hasFocus = false,
    this.animationDuration = AppAnimations.quick,
  });

  @override
  State<AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<AnimatedFormField> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderWidthAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _borderWidthAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);

    _borderColorAnimation = ColorTween(
      begin: theme.colorScheme.outline,
      end: theme.colorScheme.primary,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );
  }

  @override
  void didUpdateWidget(AnimatedFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasFocus != widget.hasFocus) {
      if (widget.hasFocus) {
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
    final theme = Theme.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              AnimatedDefaultTextStyle(
                duration: widget.animationDuration,
                style: TextStyle(
                  color: hasError
                      ? theme.colorScheme.error
                      : widget.hasFocus
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: widget.hasFocus ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(widget.label!),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasError
                      ? theme.colorScheme.error
                      : _borderColorAnimation.value ?? theme.colorScheme.outline,
                  width: hasError ? 2.0 : _borderWidthAnimation.value,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.hasFocus && !hasError
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: widget.child,
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: hasError ? 1.0 : 0.0,
                duration: widget.animationDuration,
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
