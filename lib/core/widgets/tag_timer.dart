import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/haptic_patterns.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG TIMER - Shared Timer Widget
/// ════════════════════════════════════════════════════════════════════════════
///
/// A reusable animated timer widget for timed game phases, rounds, and actions.

class TagTimer extends StatefulWidget {
  const TagTimer({
    super.key,
    required this.duration,
    this.onComplete,
    this.onTick,
    this.color = Colors.blue,
    this.secondaryColor,
    this.backgroundColor,
    this.size = 120,
    this.style = TagTimerStyle.circular,
    this.autoStart = false,
    this.showMilliseconds = false,
    this.hapticOnComplete = true,
    this.pulseWhenLow = true,
    this.lowTimeThreshold = const Duration(seconds: 5),
    this.formatDuration,
  });

  /// Total duration for the timer
  final Duration duration;

  /// Called when timer completes
  final VoidCallback? onComplete;

  /// Called every tick with remaining duration
  final ValueChanged<Duration>? onTick;

  /// Primary color for the timer
  final Color color;

  /// Secondary color for progress gradient
  final Color? secondaryColor;

  /// Background color
  final Color? backgroundColor;

  /// Size of the timer (diameter for circular, height for linear)
  final double size;

  /// Timer display style
  final TagTimerStyle style;

  /// Whether to auto-start when mounted
  final bool autoStart;

  /// Whether to show milliseconds
  final bool showMilliseconds;

  /// Whether to play haptic on complete
  final bool hapticOnComplete;

  /// Whether to pulse when low on time
  final bool pulseWhenLow;

  /// Duration threshold for "low time" warning
  final Duration lowTimeThreshold;

  /// Custom format function for display
  final String Function(Duration)? formatDuration;

  @override
  State<TagTimer> createState() => TagTimerState();
}

class TagTimerState extends State<TagTimer> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  Timer? _tickTimer;
  bool _isRunning = false;
  bool _isCompleted = false;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controller.addListener(_onAnimationTick);
    _controller.addStatusListener(_onAnimationStatus);

    if (widget.autoStart) {
      start();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _controller.removeListener(_onAnimationTick);
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    final newRemaining = Duration(
      milliseconds:
          ((1 - _controller.value) * widget.duration.inMilliseconds).round(),
    );

    if (newRemaining != _remaining) {
      setState(() => _remaining = newRemaining);
      widget.onTick?.call(_remaining);

      // Check for low time
      if (widget.pulseWhenLow &&
          _remaining <= widget.lowTimeThreshold &&
          !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isCompleted) {
      _isCompleted = true;
      _isRunning = false;
      _pulseController.stop();

      if (widget.hapticOnComplete) {
        TagHaptics.timerComplete();
      }
      widget.onComplete?.call();
    }
  }

  /// Start the timer
  void start() {
    if (_isRunning || _isCompleted) return;
    _isRunning = true;
    _controller.forward();
  }

  /// Pause the timer
  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _controller.stop();
    _pulseController.stop();
  }

  /// Resume the timer
  void resume() {
    if (_isRunning || _isCompleted) return;
    _isRunning = true;
    _controller.forward();
    if (widget.pulseWhenLow && _remaining <= widget.lowTimeThreshold) {
      _pulseController.repeat(reverse: true);
    }
  }

  /// Reset the timer
  void reset() {
    _controller.reset();
    _pulseController.reset();
    _isRunning = false;
    _isCompleted = false;
    setState(() => _remaining = widget.duration);
  }

  /// Reset and start
  void restart() {
    reset();
    start();
  }

  /// Add time to the timer
  void addTime(Duration extra) {
    // This requires recalculating the controller
    final newDuration = _remaining + extra;
    final progress =
        1 - (newDuration.inMilliseconds / widget.duration.inMilliseconds);
    _controller.value = progress.clamp(0.0, 1.0);
    setState(() => _remaining = newDuration);
  }

  /// Check if timer is running
  bool get isRunning => _isRunning;

  /// Check if timer is completed
  bool get isCompleted => _isCompleted;

  /// Get remaining duration
  Duration get remaining => _remaining;

  String _formatDuration(Duration d) {
    if (widget.formatDuration != null) {
      return widget.formatDuration!(d);
    }

    if (widget.showMilliseconds) {
      final minutes = d.inMinutes;
      final seconds = d.inSeconds % 60;
      final ms = (d.inMilliseconds % 1000) ~/ 10;
      if (minutes > 0) {
        return '$minutes:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
      }
      return '$seconds.${ms.toString().padLeft(2, '0')}';
    }

    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return seconds.toString();
  }

  @override
  Widget build(BuildContext context) => switch (widget.style) {
        TagTimerStyle.circular => _buildCircularTimer(),
        TagTimerStyle.linear => _buildLinearTimer(),
        TagTimerStyle.text => _buildTextTimer(),
        TagTimerStyle.compact => _buildCompactTimer(),
      };

  Widget _buildCircularTimer() => AnimatedBuilder(
        animation: Listenable.merge([_controller, _pulseController]),
        builder: (context, child) {
          final scale =
              widget.pulseWhenLow && _remaining <= widget.lowTimeThreshold
                  ? 1.0 + (_pulseController.value * 0.05)
                  : 1.0;

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: widget.size * 0.08,
                      backgroundColor: widget.backgroundColor ??
                          widget.color.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.transparent),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: 1 - _controller.value,
                      strokeWidth: widget.size * 0.08,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        _remaining <= widget.lowTimeThreshold
                            ? Color.lerp(widget.color, Colors.red,
                                _pulseController.value)!
                            : widget.color,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Time display
                  Text(
                    _formatDuration(_remaining),
                    style: TextStyle(
                      color: widget.color,
                      fontSize: widget.size * 0.25,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _buildLinearTimer() => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: widget.size * 0.1,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? widget.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(widget.size * 0.05),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.size * 0.05),
                child: LinearProgressIndicator(
                  value: 1 - _controller.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(widget.color),
                  minHeight: widget.size * 0.1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_remaining),
              style: TextStyle(
                color: widget.color,
                fontSize: widget.size * 0.15,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );

  Widget _buildTextTimer() => AnimatedBuilder(
        animation: Listenable.merge([_controller, _pulseController]),
        builder: (context, child) {
          final color = _remaining <= widget.lowTimeThreshold
              ? Color.lerp(widget.color, Colors.red, _pulseController.value)!
              : widget.color;

          return Text(
            _formatDuration(_remaining),
            style: TextStyle(
              color: color,
              fontSize: widget.size,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );
        },
      );

  Widget _buildCompactTimer() => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? widget.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                color: widget.color,
                size: widget.size * 0.5,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDuration(_remaining),
                style: TextStyle(
                  color: widget.color,
                  fontSize: widget.size * 0.4,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Timer display styles
enum TagTimerStyle {
  /// Circular progress indicator with time in center
  circular,

  /// Linear progress bar with time below
  linear,

  /// Just the time text
  text,

  /// Compact pill with icon
  compact,
}
