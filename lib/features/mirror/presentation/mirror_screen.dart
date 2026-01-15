import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/domain/models/analytics.dart';

/// The Mirror Screen - Analytics Dashboard
/// Ghost Rate, Flake Rate, Swipe Ratio, Response Rate with brutal truth insights
class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: analytics.when(
          data: (data) => _buildContent(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, UserAnalytics analytics) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader(context)),
          
          // Overview card
          SliverToBoxAdapter(child: _buildOverviewCard(context, analytics)),
          
          // Main metrics grid
          SliverToBoxAdapter(child: _buildMetricsGrid(context, analytics)),
          
          // Trend chart
          SliverToBoxAdapter(child: _buildTrendChart(context, analytics)),
          
          // Brutal truth section
          SliverToBoxAdapter(child: _buildBrutalTruth(context, analytics)),
          
          // Activity breakdown
          SliverToBoxAdapter(child: _buildActivityBreakdown(context, analytics)),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: VesparaSpacing.xl),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              context.go('/home');
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: VesparaColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE MIRROR',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Face your data',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: VesparaColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverviewCard(BuildContext context, UserAnalytics analytics) {
    final overallScore = _calculateOverallScore(analytics);
    final scoreColor = _getScoreColor(overallScore);
    
    return Container(
      margin: const EdgeInsets.all(VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VesparaColors.surface,
            scoreColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Score circle
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: VesparaColors.background,
                    valueColor: AlwaysStoppedAnimation(
                      VesparaColors.inactive.withOpacity(0.3),
                    ),
                  ),
                ),
                // Progress ring
                SizedBox(
                  width: 100,
                  height: 100,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: overallScore / 100),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      );
                    },
                  ),
                ),
                // Score text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: overallScore),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Text(
                      'SCORE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: VesparaSpacing.lg),
          
          // Score breakdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getScoreLabel(overallScore),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreDescription(overallScore),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: VesparaSpacing.md),
                Row(
                  children: [
                    _buildMiniStat(
                      context,
                      '${analytics.totalMatches}',
                      'Total',
                    ),
                    const SizedBox(width: VesparaSpacing.md),
                    _buildMiniStat(
                      context,
                      '${analytics.activeConversations}',
                      'Active',
                    ),
                    const SizedBox(width: VesparaSpacing.md),
                    _buildMiniStat(
                      context,
                      '${analytics.datesScheduled}',
                      'Dates',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
  
  Widget _buildMetricsGrid(BuildContext context, UserAnalytics analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: Icons.visibility_off,
                  label: 'GHOST RATE',
                  value: analytics.ghostRate,
                  description: 'Conversations that faded',
                  isNegative: true,
                ),
              ),
              const SizedBox(width: VesparaSpacing.sm),
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: Icons.event_busy,
                  label: 'FLAKE RATE',
                  value: analytics.flakeRate,
                  description: 'Plans that fell through',
                  isNegative: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: Icons.swap_horiz,
                  label: 'SWIPE RATIO',
                  value: analytics.swipeRatio,
                  description: 'Right vs left swipes',
                  isNegative: false,
                ),
              ),
              const SizedBox(width: VesparaSpacing.sm),
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: Icons.reply,
                  label: 'RESPONSE RATE',
                  value: analytics.responseRate,
                  description: 'Messages answered',
                  isNegative: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required String description,
    required bool isNegative,
  }) {
    // For negative metrics, lower is better
    final color = isNegative
        ? (value < 20 ? VesparaColors.tagsGreen : 
           (value < 50 ? VesparaColors.tagsYellow : VesparaColors.tagsRed))
        : (value > 70 ? VesparaColors.tagsGreen : 
           (value > 40 ? VesparaColors.tagsYellow : VesparaColors.tagsRed));
    
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
            ),
          ),
          const SizedBox(height: VesparaSpacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: VesparaColors.background,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendChart(BuildContext context, UserAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.all(VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVITY TREND',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: VesparaColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last 7 days',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Simple chart visualization
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _TrendChartPainter(
                data: analytics.weeklyActivity,
                color: VesparaColors.glow,
              ),
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.md),
          
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Text(
                      day,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBrutalTruth(BuildContext context, UserAnalytics analytics) {
    final insights = _generateInsights(analytics);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
        border: Border.all(
          color: VesparaColors.tagsYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VesparaColors.tagsYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: VesparaColors.tagsYellow,
                  size: 24,
                ),
              ),
              const SizedBox(width: VesparaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BRUTAL TRUTH',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 2,
                        color: VesparaColors.tagsYellow,
                      ),
                    ),
                    Text(
                      'Honest insights from your data',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          ...insights.map((insight) => _buildInsightItem(context, insight)),
        ],
      ),
    );
  }
  
  Widget _buildInsightItem(BuildContext context, Map<String, dynamic> insight) {
    final IconData icon = insight['icon'] as IconData;
    final String text = insight['text'] as String;
    final Color color = insight['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: VesparaSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: VesparaSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityBreakdown(BuildContext context, UserAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.all(VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVITY BREAKDOWN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          _buildActivityRow(
            context,
            label: 'Messages Sent',
            value: analytics.messagesSent,
            total: analytics.messagesSent + analytics.messagesReceived,
            color: VesparaColors.glow,
          ),
          _buildActivityRow(
            context,
            label: 'Messages Received',
            value: analytics.messagesReceived,
            total: analytics.messagesSent + analytics.messagesReceived,
            color: VesparaColors.secondary,
          ),
          
          const Divider(color: VesparaColors.border, height: 32),
          
          _buildActivityRow(
            context,
            label: 'First Messages Sent',
            value: analytics.firstMessagesSent,
            total: analytics.totalMatches,
            color: VesparaColors.tagsGreen,
          ),
          _buildActivityRow(
            context,
            label: 'Conversations Started',
            value: analytics.conversationsStarted,
            total: analytics.totalMatches,
            color: VesparaColors.tagsYellow,
          ),
          
          const Divider(color: VesparaColors.border, height: 32),
          
          // Peak activity time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peak Activity',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'When you\'re most active',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analytics.peakActivityTime,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: VesparaColors.glow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityRow(
    BuildContext context, {
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (value / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: VesparaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: VesparaColors.background,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  double _calculateOverallScore(UserAnalytics analytics) {
    // Weight different metrics
    final responseWeight = analytics.responseRate * 0.3;
    final ghostPenalty = (100 - analytics.ghostRate) * 0.25;
    final flakePenalty = (100 - analytics.flakeRate) * 0.25;
    final activityBonus = math.min(analytics.swipeRatio * 0.2, 20);
    
    return (responseWeight + ghostPenalty + flakePenalty + activityBonus)
        .clamp(0, 100);
  }
  
  Color _getScoreColor(double score) {
    if (score >= 75) return VesparaColors.tagsGreen;
    if (score >= 50) return VesparaColors.tagsYellow;
    return VesparaColors.tagsRed;
  }
  
  String _getScoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Strong';
    if (score >= 50) return 'Average';
    if (score >= 30) return 'Needs Work';
    return 'Critical';
  }
  
  String _getScoreDescription(double score) {
    if (score >= 85) return 'You\'re crushing it. Keep the momentum.';
    if (score >= 70) return 'Solid performance with room to grow.';
    if (score >= 50) return 'Middle of the pack. Time to step up.';
    if (score >= 30) return 'Your metrics need serious attention.';
    return 'Major changes needed. Let\'s fix this.';
  }
  
  List<Map<String, dynamic>> _generateInsights(UserAnalytics analytics) {
    final insights = <Map<String, dynamic>>[];
    
    // Ghost rate insight
    if (analytics.ghostRate > 50) {
      insights.add({
        'icon': Icons.visibility_off,
        'text': 'You\'re ghosting over half your matches. Either engage meaningfully or clean up your roster.',
        'color': VesparaColors.tagsRed,
      });
    } else if (analytics.ghostRate > 25) {
      insights.add({
        'icon': Icons.visibility_off,
        'text': 'Your ghost rate is creeping up. Consider using The Shredder for graceful exits.',
        'color': VesparaColors.tagsYellow,
      });
    }
    
    // Response rate insight
    if (analytics.responseRate < 40) {
      insights.add({
        'icon': Icons.reply,
        'text': 'Your response rate is low. Try the Conversation Resuscitator in The Wire.',
        'color': VesparaColors.tagsRed,
      });
    } else if (analytics.responseRate > 80) {
      insights.add({
        'icon': Icons.reply,
        'text': 'Excellent response rate! You\'re keeping conversations alive.',
        'color': VesparaColors.tagsGreen,
      });
    }
    
    // Flake rate insight
    if (analytics.flakeRate > 40) {
      insights.add({
        'icon': Icons.event_busy,
        'text': 'Too many plans falling through. Only confirm dates you\'ll actually keep.',
        'color': VesparaColors.tagsRed,
      });
    }
    
    // First message insight
    if (analytics.firstMessagesSent < analytics.totalMatches * 0.3) {
      insights.add({
        'icon': Icons.send,
        'text': 'You\'re waiting for others to message first. Take initiative.',
        'color': VesparaColors.tagsYellow,
      });
    }
    
    // Add a positive if nothing else
    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.star,
        'text': 'Your metrics look healthy. Keep doing what you\'re doing.',
        'color': VesparaColors.tagsGreen,
      });
    }
    
    return insights;
  }
}

/// Custom painter for the trend chart
class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  
  _TrendChartPainter({
    required this.data,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;
    
    final path = Path();
    final fillPath = Path();
    
    final stepX = size.width / (data.length - 1);
    
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 
          ? (data[i] - minValue) / range 
          : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8) - (size.height * 0.1);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 
          ? (data[i] - minValue) / range 
          : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8) - (size.height * 0.1);
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(
        Offset(x, y), 
        2, 
        Paint()..color = VesparaColors.surface,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
