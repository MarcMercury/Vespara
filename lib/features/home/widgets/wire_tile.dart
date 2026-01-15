import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

/// Tile 4: The Wire - Messaging
/// Displays list of active chats sorted by Momentum Score
class WireTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const WireTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final staleConversations = ref.watch(staleConversationsProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VesparaGlass.tile,
        child: Padding(
          padding: const EdgeInsets.all(VesparaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // HEADER
              // ═══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'THE WIRE',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      letterSpacing: 2,
                      color: VesparaColors.secondary,
                    ),
                  ),
                  Row(
                    children: [
                      // Stale indicator
                      if (staleConversations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: VesparaColors.tagsYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${staleConversations.length} stale',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: VesparaColors.tagsYellow,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: VesparaColors.glow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: VesparaColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Spacer(),
              
              // ═══════════════════════════════════════════════════════════════
              // CHAT PREVIEW LIST
              // ═══════════════════════════════════════════════════════════════
              conversations.when(
                data: (convos) => _buildChatPreview(context, convos.take(3).toList()),
                loading: () => _buildChatPreviewShimmer(),
                error: (_, __) => _buildEmptyState(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChatPreview(BuildContext context, List convos) {
    if (convos.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Column(
      children: convos.map((convo) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VesparaColors.surface,
                  border: Border.all(
                    color: VesparaColors.glow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              // Message preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      convo.matchName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: VesparaColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (convo.lastMessage != null)
                      Text(
                        convo.lastMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Momentum indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getMomentumColor(convo.momentumScore),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Color _getMomentumColor(double score) {
    if (score > 0.7) return VesparaColors.tagsGreen;
    if (score > 0.4) return VesparaColors.tagsYellow;
    return VesparaColors.tagsRed;
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        'No active chats',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
  
  Widget _buildChatPreviewShimmer() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VesparaColors.shimmerBase,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: VesparaColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
