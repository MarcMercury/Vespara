import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WIRE VOICE RECORDER - WhatsApp-Style Voice Recording Widget
/// ════════════════════════════════════════════════════════════════════════════

class WireVoiceRecorder extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  final Function(String path, int durationSeconds, List<double> waveform) onSend;
  final VoidCallback? onLock;
  
  const WireVoiceRecorder({
    super.key,
    required this.onCancel,
    required this.onSend,
    this.onLock,
  });

  @override
  ConsumerState<WireVoiceRecorder> createState() => _WireVoiceRecorderState();
}

class _WireVoiceRecorderState extends ConsumerState<WireVoiceRecorder>
    with TickerProviderStateMixin {
  
  // Recording state
  bool _isRecording = false;
  bool _isLocked = false;
  bool _isPaused = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  
  // Waveform data
  final List<double> _waveformData = [];
  final Random _random = Random();
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  
  // Gesture tracking
  double _dragOffset = 0;
  bool _slidToCancel = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _waveformData.clear();
    });
    
    VesparaHaptics.lightTap();
    
    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _recordingSeconds++;
          // Simulate waveform data
          _waveformData.add(0.2 + _random.nextDouble() * 0.8);
        });
      }
    });
    
    // In production, you would start actual audio recording here
    // using audio_recorder or record package
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = true;
    });
    VesparaHaptics.lightTap();
  }

  void _resumeRecording() {
    setState(() {
      _isPaused = false;
    });
    VesparaHaptics.lightTap();
  }

  void _cancelRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
    VesparaHaptics.mediumTap();
    widget.onCancel();
  }

  void _sendRecording() {
    _timer?.cancel();
    
    if (_recordingSeconds < 1) {
      // Too short
      VesparaHaptics.error();
      widget.onCancel();
      return;
    }
    
    VesparaHaptics.success();
    
    // In production, stop recording and get the file path
    // For now, simulate with a mock path
    final mockPath = '/recordings/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    widget.onSend(mockPath, _recordingSeconds, _waveformData);
  }

  void _lockRecording() {
    setState(() {
      _isLocked = true;
    });
    VesparaHaptics.mediumTap();
    widget.onLock?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return _buildLockedRecorder();
    }
    
    return _buildSlideRecorder();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIDE TO CANCEL MODE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSlideRecorder() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          if (_dragOffset < -100) {
            _slidToCancel = true;
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_slidToCancel) {
          _cancelRecording();
        } else {
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -50 && !_isLocked) {
          _lockRecording();
        }
      },
      child: Container(
        height: 56,
        color: VesparaColors.surface,
        child: Row(
          children: [
            // Slide to cancel indicator
            Expanded(
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    
                    // Recording indicator
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 12 * _pulseAnimation.value,
                          height: 12 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            color: VesparaColors.tagsRed,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Duration
                    Text(
                      _formatDuration(_recordingSeconds),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: VesparaColors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Slide to cancel
                    Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: VesparaColors.secondary.withOpacity(
                            _slidToCancel ? 1.0 : 0.5,
                          ),
                          size: 20,
                        ),
                        Text(
                          _slidToCancel ? 'Release to cancel' : 'Slide to cancel',
                          style: TextStyle(
                            fontSize: 14,
                            color: _slidToCancel 
                                ? VesparaColors.tagsRed 
                                : VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            
            // Lock indicator
            Container(
              width: 56,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: VesparaColors.secondary,
                    size: 16,
                  ),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: VesparaColors.secondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOCKED MODE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLockedRecorder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: VesparaColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform visualization
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Recording indicator
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: VesparaColors.tagsRed,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                
                // Duration
                Text(
                  _formatDuration(_recordingSeconds),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Waveform bars
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _buildWaveformBars(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Controls
          Row(
            children: [
              // Delete button
              GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: VesparaColors.tagsRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: VesparaColors.tagsRed,
                    size: 22,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Pause/Resume button
              GestureDetector(
                onTap: _isPaused ? _resumeRecording : _pauseRecording,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: VesparaColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: VesparaColors.primary,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Send button
              GestureDetector(
                onTap: _sendRecording,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: VesparaColors.glow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: VesparaColors.background,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWaveformBars() {
    final displayCount = min(_waveformData.length, 30);
    final startIndex = max(0, _waveformData.length - displayCount);
    
    return List.generate(displayCount, (index) {
      final dataIndex = startIndex + index;
      final amplitude = _waveformData.elementAtOrNull(dataIndex) ?? 0.3;
      
      return Container(
        width: 3,
        height: 4 + (amplitude * 28),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: _isPaused 
              ? VesparaColors.secondary 
              : VesparaColors.glow,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}


/// ════════════════════════════════════════════════════════════════════════════
/// VOICE MESSAGE PLAYER - For playing recorded voice messages
/// ════════════════════════════════════════════════════════════════════════════

class VoiceMessagePlayer extends ConsumerStatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final List<double>? waveform;
  final bool isMe;
  
  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    this.waveform,
    this.isMe = false,
  });

  @override
  ConsumerState<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  bool _isPlaying = false;
  double _progress = 0;
  int _currentSeconds = 0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    VesparaHaptics.lightTap();
    setState(() {
      _isPlaying = true;
    });
    
    // Simulate playback progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.1 / widget.durationSeconds;
        _currentSeconds = (_progress * widget.durationSeconds).floor();
        
        if (_progress >= 1.0) {
          _progress = 0;
          _currentSeconds = 0;
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
    
    // In production, use audio player package to play the audio
  }

  void _pause() {
    _progressTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final waveformData = widget.waveform ?? List.generate(20, (i) => 0.3 + (i % 3) * 0.2);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: VesparaColors.glow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: VesparaColors.background,
              size: 24,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Waveform with progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Waveform
              SizedBox(
                height: 24,
                child: Row(
                  children: List.generate(waveformData.length, (index) {
                    final isPlayed = index / waveformData.length <= _progress;
                    return Expanded(
                      child: Container(
                        height: 4 + (waveformData[index] * 16),
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isPlayed 
                              ? VesparaColors.glow 
                              : VesparaColors.glow.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Duration
              Text(
                _isPlaying || _progress > 0
                    ? _formatDuration(_currentSeconds)
                    : _formatDuration(widget.durationSeconds),
                style: TextStyle(
                  fontSize: 11,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
