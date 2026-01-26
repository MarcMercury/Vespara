import 'package:flutter/material.dart';
import '../utils/haptic_patterns.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG ACTION BUTTON - Shared Action Button
/// ════════════════════════════════════════════════════════════════════════════
///
/// A reusable animated button for game actions like "Start", "Next", "Skip", etc.

class TagActionButton extends StatefulWidget {
  const TagActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = Colors.blue,
    this.icon,
    this.iconLeft = true,
    this.size = TagActionButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
    this.style = TagActionButtonStyle.filled,
    this.width,
    this.hapticPattern = TagHapticPattern.selection,
  });

  /// Primary action button (filled, prominent)
  factory TagActionButton.primary({
    required String label,
    required VoidCallback? onPressed,
    Color color = Colors.blue,
    IconData? icon,
    bool isLoading = false,
    bool disabled = false,
  }) =>
      TagActionButton(
        label: label,
        onPressed: onPressed,
        color: color,
        icon: icon,
        size: TagActionButtonSize.large,
        isLoading: isLoading,
        disabled: disabled,
        hapticPattern: TagHapticPattern.success,
      );

  /// Secondary action button (outlined)
  factory TagActionButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    Color color = Colors.white,
    IconData? icon,
    bool disabled = false,
  }) =>
      TagActionButton(
        label: label,
        onPressed: onPressed,
        color: color,
        icon: icon,
        style: TagActionButtonStyle.outlined,
        disabled: disabled,
      );

  /// Destructive action button (red, for skip/quit)
  factory TagActionButton.destructive({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool disabled = false,
  }) =>
      TagActionButton(
        label: label,
        onPressed: onPressed,
        color: Colors.red,
        icon: icon,
        style: TagActionButtonStyle.outlined,
        disabled: disabled,
        hapticPattern: TagHapticPattern.warning,
      );

  /// Button label
  final String label;

  /// Called when button is tapped
  final VoidCallback? onPressed;

  /// Primary color
  final Color color;

  /// Icon to display (optional)
  final IconData? icon;

  /// Whether icon is on left (true) or right (false)
  final bool iconLeft;

  /// Button size
  final TagActionButtonSize size;

  /// Whether button is loading
  final bool isLoading;

  /// Whether button is disabled
  final bool disabled;

  /// Button style variant
  final TagActionButtonStyle style;

  /// Custom width (null for auto)
  final double? width;

  /// Haptic pattern to play on tap
  final TagHapticPattern hapticPattern;

  @override
  State<TagActionButton> createState() => _TagActionButtonState();
}

class _TagActionButtonState extends State<TagActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  double get _height => switch (widget.size) {
        TagActionButtonSize.small => 36,
        TagActionButtonSize.medium => 48,
        TagActionButtonSize.large => 56,
      };

  double get _fontSize => switch (widget.size) {
        TagActionButtonSize.small => 13,
        TagActionButtonSize.medium => 15,
        TagActionButtonSize.large => 17,
      };

  double get _iconSize => switch (widget.size) {
        TagActionButtonSize.small => 16,
        TagActionButtonSize.medium => 20,
        TagActionButtonSize.large => 24,
      };

  EdgeInsets get _padding => switch (widget.size) {
        TagActionButtonSize.small => const EdgeInsets.symmetric(horizontal: 16),
        TagActionButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: 24),
        TagActionButtonSize.large => const EdgeInsets.symmetric(horizontal: 32),
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.disabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.disabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.disabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.disabled || widget.isLoading) return;
    _playHaptic();
    widget.onPressed?.call();
  }

  void _playHaptic() {
    switch (widget.hapticPattern) {
      case TagHapticPattern.selection:
        TagHaptics.selection();
        break;
      case TagHapticPattern.success:
        TagHaptics.success();
        break;
      case TagHapticPattern.warning:
        TagHaptics.warning();
        break;
      case TagHapticPattern.error:
        TagHaptics.error();
        break;
      case TagHapticPattern.impact:
        TagHaptics.heavyImpact();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.isLoading;
    final opacity = isDisabled ? 0.4 : 1.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.03);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          child: Container(
            height: _height,
            width: widget.width,
            padding: _padding,
            decoration: _buildDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    switch (widget.style) {
      case TagActionButtonStyle.filled:
        return BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(_height / 2),
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
      case TagActionButtonStyle.outlined:
        return BoxDecoration(
          color:
              _isPressed ? widget.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(
            color: widget.color,
            width: 2,
          ),
        );
      case TagActionButtonStyle.ghost:
        return BoxDecoration(
          color:
              _isPressed ? widget.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(_height / 2),
        );
    }
  }

  List<Widget> _buildContent() {
    final textColor = switch (widget.style) {
      TagActionButtonStyle.filled => _getContrastColor(widget.color),
      TagActionButtonStyle.outlined => widget.color,
      TagActionButtonStyle.ghost => widget.color,
    };

    if (widget.isLoading) {
      return [
        SizedBox(
          width: _iconSize,
          height: _iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(textColor),
          ),
        ),
      ];
    }

    final icon = widget.icon != null
        ? Icon(widget.icon, size: _iconSize, color: textColor)
        : null;

    final label = Text(
      widget.label,
      style: TextStyle(
        color: textColor,
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    if (icon == null) {
      return [label];
    }

    if (widget.iconLeft) {
      return [
        icon,
        const SizedBox(width: 8),
        label,
      ];
    }

    return [
      label,
      const SizedBox(width: 8),
      icon,
    ];
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

enum TagActionButtonSize { small, medium, large }

enum TagActionButtonStyle { filled, outlined, ghost }

enum TagHapticPattern { selection, success, warning, error, impact }

/// ════════════════════════════════════════════════════════════════════════════
/// TAG ICON BUTTON - Circular Icon Button
/// ════════════════════════════════════════════════════════════════════════════

class TagIconButton extends StatelessWidget {
  const TagIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = Colors.white,
    this.size = 48,
    this.filled = false,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: () {
        TagHaptics.selection();
        onPressed?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          color: filled ? _getContrastColor(color) : color,
          size: size * 0.5,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }

    return button;
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
