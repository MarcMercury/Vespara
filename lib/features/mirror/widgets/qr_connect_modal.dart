import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/connection_state_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// QR CONNECT MODAL
/// Instant connection via QR code scanning
/// "Meet. Scan. Connect. That simple."
/// ════════════════════════════════════════════════════════════════════════════

class QrConnectModal extends ConsumerStatefulWidget {
  const QrConnectModal({super.key});

  @override
  ConsumerState<QrConnectModal> createState() => _QrConnectModalState();
}

class _QrConnectModalState extends ConsumerState<QrConnectModal> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  String? _scannedResult;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: VesparaColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VesparaColors.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            VesparaColors.glow,
                            VesparaColors.primary,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: VesparaColors.glow.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: VesparaColors.background,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INSTANT CONNECT',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: VesparaColors.primary,
                          ),
                        ),
                        Text(
                          'Scan to connect in person',
                          style: TextStyle(
                            fontSize: 14,
                            color: VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [VesparaColors.glow, VesparaColors.primary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: VesparaColors.background,
              unselectedLabelColor: VesparaColors.secondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'MY CODE'),
                Tab(text: 'SCAN'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyCodeTab(),
                _buildScanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// My QR Code tab - shows your code for others to scan
  Widget _buildMyCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // QR Code display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: VesparaColors.glow.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: VesparaColors.glow.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Simulated QR Code (in production, use qr_flutter package)
                _buildQrCodeDisplay(),
                
                const SizedBox(height: 20),
                
                Text(
                  'YOUR PROFILE',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: VesparaColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Alex Morgan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: VesparaColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@alex_vespara',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: VesparaColors.glow,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Show this code to someone you meet. They scan it with their Vespara app to instantly connect.',
                    style: TextStyle(
                      color: VesparaColors.secondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.link, color: VesparaColors.glow),
                        const SizedBox(width: 12),
                        Text('Profile link copied!'),
                      ],
                    ),
                    backgroundColor: VesparaColors.surface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('SHARE LINK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.surface,
                foregroundColor: VesparaColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Simulated QR code display
  Widget _buildQrCodeDisplay() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: const Size(168, 168),
        painter: QrCodePainter(),
      ),
    );
  }

  /// Scan tab - camera view to scan others' codes
  Widget _buildScanTab() {
    if (_showSuccess) {
      return _buildSuccessView();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Scanner frame
          Expanded(
            child: GestureDetector(
              onTap: _simulateScan,
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: VesparaColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isScanning 
                        ? VesparaColors.glow 
                        : VesparaColors.secondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera placeholder
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isScanning ? Icons.qr_code_scanner : Icons.camera_alt,
                          size: 64,
                          color: VesparaColors.glow.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning ? 'Scanning...' : 'Tap to activate camera',
                          style: TextStyle(
                            color: VesparaColors.secondary,
                            fontSize: 16,
                          ),
                        ),
                        if (!_isScanning) ...[
                          const SizedBox(height: 8),
                          Text(
                            '(Demo: Tap to simulate scan)',
                            style: TextStyle(
                              color: VesparaColors.secondary.withOpacity(0.5),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Scan frame overlay
                    if (_isScanning)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ScanFramePainter(),
                        ),
                      ),

                    // Scanning animation
                    if (_isScanning)
                      _ScanningLine(),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: VesparaColors.glow,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Point your camera at someone\'s Vespara QR code to instantly connect.',
                    style: TextStyle(
                      color: VesparaColors.secondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Simulate a QR scan (for demo purposes)
  void _simulateScan() async {
    if (_isScanning) return;

    HapticFeedback.mediumImpact();
    setState(() => _isScanning = true);

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      HapticFeedback.heavyImpact();
      
      // Add the connection
      ref.read(connectionStateProvider.notifier).connectViaQr(
        'scanned-user-${DateTime.now().millisecondsSinceEpoch}',
        'Jordan Rivers',
        null,
      );

      setState(() {
        _isScanning = false;
        _showSuccess = true;
      });
    }
  }

  /// Success view after scanning
  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [VesparaColors.glow, VesparaColors.primary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VesparaColors.glow.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: VesparaColors.background,
                    size: 60,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          Text(
            'CONNECTED!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: VesparaColors.glow,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'You\'re now connected with',
            style: TextStyle(
              fontSize: 16,
              color: VesparaColors.secondary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Jordan Rivers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),

          const SizedBox(height: 40),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to chat
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('MESSAGE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  foregroundColor: VesparaColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _showSuccess = false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: VesparaColors.primary,
                  side: BorderSide(color: VesparaColors.secondary.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('SCAN MORE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for QR code simulation
class QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 21;
    final random = math.Random(42); // Fixed seed for consistent pattern

    // Draw position patterns (corners)
    _drawPositionPattern(canvas, paint, 0, 0, cellSize);
    _drawPositionPattern(canvas, paint, size.width - 7 * cellSize, 0, cellSize);
    _drawPositionPattern(canvas, paint, 0, size.height - 7 * cellSize, cellSize);

    // Draw random data pattern
    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        // Skip position patterns
        if ((i < 8 && j < 8) || (i < 8 && j > 12) || (i > 12 && j < 8)) {
          continue;
        }
        
        if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(j * cellSize, i * cellSize, cellSize * 0.9, cellSize * 0.9),
            paint,
          );
        }
      }
    }
  }

  void _drawPositionPattern(Canvas canvas, Paint paint, double x, double y, double cellSize) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, 7 * cellSize, 7 * cellSize), paint);
    
    // White inner
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize), paint);
    
    // Black center
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(x + 2 * cellSize, y + 2 * cellSize, 3 * cellSize, 3 * cellSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Scanner frame overlay painter
class ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VesparaColors.glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cornerLength = 40.0;
    final margin = 40.0;

    // Top left corner
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + cornerLength),
      paint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerLength),
      paint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - cornerLength),
      paint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated scanning line
class _ScanningLine extends StatefulWidget {
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
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
        return Positioned(
          top: 60 + (_controller.value * 280),
          left: 40,
          right: 40,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  VesparaColors.glow,
                  VesparaColors.glow,
                  Colors.transparent,
                ],
                stops: const [0, 0.3, 0.7, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: VesparaColors.glow.withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Show the QR Connect modal
void showQrConnectModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QrConnectModal(),
  );
}
