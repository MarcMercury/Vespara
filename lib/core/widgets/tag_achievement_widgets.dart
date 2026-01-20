import 'package:flutter/material.dart';
import '../services/tag_achievements_service.dart';
import '../utils/haptic_patterns.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG ACHIEVEMENT WIDGETS
/// ════════════════════════════════════════════════════════════════════════════
///
/// UI components for displaying achievements across the app.

// ═══════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT UNLOCK OVERLAY
// ═══════════════════════════════════════════════════════════════════════════

/// Full-screen overlay for celebrating achievement unlocks
class AchievementUnlockOverlay extends StatefulWidget {
  final TagAchievement achievement;
  final VoidCallback onDismiss;

  const AchievementUnlockOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  /// Show the overlay as a dialog
  static Future<void> show(BuildContext context, TagAchievement achievement) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AchievementUnlockOverlay(
          achievement: achievement,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AchievementUnlockOverlay> createState() => _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Play achievement haptic
    TagHaptics.achievement();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_glowController, _bounceController]),
            builder: (context, child) {
              final bounce = Curves.elasticOut.transform(_bounceController.value);
              
              return Transform.scale(
                scale: bounce,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.achievement.rarityColor.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.achievement.rarityColor.withOpacity(0.3 + _glowController.value * 0.2),
                        blurRadius: 30 + _glowController.value * 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Achievement Unlocked text
                      Text(
                        'ACHIEVEMENT UNLOCKED',
                        style: TextStyle(
                          color: widget.achievement.rarityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Icon with glow
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.achievement.rarityColor.withOpacity(0.3),
                              widget.achievement.rarityColor.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.achievement.rarityColor.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.achievement.iconData,
                          size: 56,
                          color: widget.achievement.rarityColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Achievement name
                      Text(
                        widget.achievement.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        widget.achievement.description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Points and rarity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge(
                            '+${widget.achievement.points}',
                            Icons.star,
                            Colors.amber,
                          ),
                          const SizedBox(width: 12),
                          _buildBadge(
                            widget.achievement.rarity.displayName,
                            null,
                            widget.achievement.rarityColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Tap to dismiss
                      Text(
                        'Tap to dismiss',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData? icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT CARD
// ═══════════════════════════════════════════════════════════════════════════

/// Card for displaying an achievement in a list
class AchievementCard extends StatelessWidget {
  final TagAchievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AchievementProgress? progress;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHidden = achievement.isHidden && !isUnlocked;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked 
              ? achievement.rarityColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked 
                ? achievement.rarityColor.withOpacity(0.3)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? achievement.rarityColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHidden ? Icons.lock_outline : achievement.iconData,
                size: 28,
                color: isUnlocked
                    ? achievement.rarityColor
                    : Colors.white38,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    isHidden ? '???' : achievement.name,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    isHidden ? 'Hidden achievement' : achievement.description,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Progress bar
                  if (progress != null && !isUnlocked) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress!.percentage,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation(
                                achievement.rarityColor.withOpacity(0.7),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${progress!.currentValue}/${progress!.targetValue}',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Unlocked date
                  if (unlockedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Unlocked ${_formatDate(unlockedAt!)}',
                      style: TextStyle(
                        color: achievement.rarityColor.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: achievement.rarityColor.withOpacity(isUnlocked ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: isUnlocked 
                            ? Colors.amber 
                            : Colors.white38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.points}',
                        style: TextStyle(
                          color: isUnlocked 
                              ? Colors.amber 
                              : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.rarity.displayName,
                  style: TextStyle(
                    color: isUnlocked 
                        ? achievement.rarityColor 
                        : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT SUMMARY WIDGET
// ═══════════════════════════════════════════════════════════════════════════

/// Compact summary of user's achievements
class AchievementSummaryWidget extends StatelessWidget {
  final AchievementSummary summary;
  final VoidCallback? onViewAll;

  const AchievementSummaryWidget({
    super.key,
    required this.summary,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.15),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats row
          Row(
            children: [
              _buildStat(
                '${summary.totalUnlocked}/${summary.totalAvailable}',
                'Unlocked',
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 16),
              _buildStat(
                '${summary.totalPoints}',
                'Points',
                Icons.star_outline,
              ),
              const SizedBox(width: 16),
              _buildStat(
                '${(summary.completionPercentage * 100).toInt()}%',
                'Complete',
                Icons.pie_chart_outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.completionPercentage,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(Colors.amber),
              minHeight: 8,
            ),
          ),
          
          // Rarity breakdown
          if (summary.unlockedByRarity.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.unlockedByRarity.entries.map((e) {
                final rarity = AchievementRarity.fromString(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rarity.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${e.value} ${rarity.displayName}',
                    style: TextStyle(
                      color: rarity.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MINI ACHIEVEMENT BADGE
// ═══════════════════════════════════════════════════════════════════════════

/// Small badge for displaying recent unlocks in game
class MiniAchievementBadge extends StatelessWidget {
  final TagAchievement achievement;
  final VoidCallback? onTap;

  const MiniAchievementBadge({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: achievement.rarityColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: achievement.rarityColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achievement.iconData,
              size: 18,
              color: achievement.rarityColor,
            ),
            const SizedBox(width: 8),
            Text(
              achievement.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 10, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    '+${achievement.points}',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
