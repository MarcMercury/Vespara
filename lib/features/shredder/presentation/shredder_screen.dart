import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THE SHREDDER - Module 7
/// AI-powered "time to move on" recommendations
/// Brutally honest about dead-end connections
/// ════════════════════════════════════════════════════════════════════════════

class ShredderScreen extends ConsumerStatefulWidget {
  const ShredderScreen({super.key});

  @override
  ConsumerState<ShredderScreen> createState() => _ShredderScreenState();
}

class _ShredderScreenState extends ConsumerState<ShredderScreen> {
  List<Map<String, dynamic>> _suggestions = [];
  final List<Map<String, dynamic>> _shreddedHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaleMatches();
  }

  /// Load matches with no recent interaction from the database
  Future<void> _loadStaleMatches() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        return;
      }

      // Get matches older than 14 days with no first_message (never messaged)
      // or where first_message is older than 30 days
      final staleDate = DateTime.now().subtract(const Duration(days: 14));
      final veryStaleDate = DateTime.now().subtract(const Duration(days: 30));

      // Query matches where user is user_a
      final matchesAsA = await supabase
          .from('matches')
          .select('''
            id,
            matched_at,
            first_message_at,
            user_b_id,
            user_a_archived,
            matched_user:profiles!matches_user_b_id_fkey (
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('user_a_id', userId)
          .eq('user_a_archived', false)
          .lt('matched_at', staleDate.toIso8601String());

      // Query matches where user is user_b
      final matchesAsB = await supabase
          .from('matches')
          .select('''
            id,
            matched_at,
            first_message_at,
            user_a_id,
            user_b_archived,
            matched_user:profiles!matches_user_a_id_fkey (
              id,_isLoading
      ? const Center(
          child: CircularProgressIndicator(color: VesparaColors.error),
        )
      : RefreshIndicator(
          onRefresh: _loadStaleMatches,
          color: VesparaColors.error,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 24),
                if (_suggestions.isEmpty)
                  _buildEmptyState()
                else ...[
                  const Text(
                    'AI SUGGESTS YOU LET GO OF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._suggestions.map(_buildSuggestionCard),
                ],
              ],
            ),
          ),
          String reason;
        
        if (firstMessageAt == null) {
          // Never messaged
          if (daysSinceMatch > 30) {
            urgency = 'high';
            reason = 'Matched over a month ago with zero messages exchanged';
          } else {
            urgency = 'medium';
            reason = 'No conversation started since matching';
          }
        } else if (firstMessageAt.isBefore(veryStaleDate)) {
          urgency = 'high';
          reason = 'Last message was over a month ago';
        } else {
          urgency = 'low';
          reason = 'Conversation has gone quiet';
        }

        suggestions.add({
          'id': match['id'],
          'matchedUserId': matchedUser['id'],
          'name': matchedUser['display_name'] ?? 'Someone',
          'avatarUrl': matchedUser['avatar_url'],
          'daysSinceMatch': daysSinceMatch,
          'urgency': urgency,
          'reason': reason,
          'hasNeverMessaged': firstMessageAt == null,
        });
      }

      // Sort by urgency (high first) then by days since match
      suggestions.sort((a, b) {
        final urgencyOrder = {'high': 0, 'medium': 1, 'low': 2};
        final aOrder = urgencyOrder[a['urgency']] ?? 2;
        final bOrder = urgencyOrder[b['urgency']] ?? 2;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return (b['daysSinceMatch'] as int).compareTo(a['daysSinceMatch'] as int);
      });

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stale matches: $e');
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            const Column(
              children: [
                Text(
                  'THE SHREDDER',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: VesparaColors.error,
                  ),
                ),
                Text(
                  'Time to let go',
                  style: TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _showHistoryDialog,
              icon: const Icon(Icons.history, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildContent() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(),
            const SizedBox(height: 24),
            if (_suggestions.isEmpty)
              _buildEmptyState()
            else ...[
              const Text(
                'AI SUGGESTS YOU LET GO OF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.secondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ..._suggestions.map(_buildSuggestionCard),
            ],
          ],
        ),
      );

  Widget _buildIntroCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.error.withOpacity(0.3),
              VesparaColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VesparaColors.error.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.delete_sweep,
                size: 40,
                color: VesparaColors.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Some connections have run their course',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The AI has analyzed your conversations, response patterns, and energy levels to identify connections that may not be serving you anymore.',
              style: TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology,
                      size: 16, color: VesparaColors.glow,),
                  const SizedBox(width: 8),
                  Text(
                    '${_suggestions.length} connections flagged for review',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.glow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 80,
              color: VesparaColors.success.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'All connections look healthy!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nothing to shred right now. Keep nurturing your roster!',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final urgency = suggestion['urgency'] as String;
    final urgencyColor = urgency == 'high'
        ? VesparaColors.error
        : (urgency == 'medium'
            ? VesparaColors.warning
            : VesparaColors.secondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgencyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with urgency
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.glow.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      (suggestion['name'] as String)[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                      Text(
                        'Matched ${suggestion['daysSinceMatch']} days ago',
                        style: const TextStyle(
                          fontSize: 12,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    urgency.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: VesparaColors.background,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reason
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: VesparaColors.glow,),
                    SizedBox(width: 8),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.glow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion['reason'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Stats
                _buildShredStats(suggestion),
async {
              Navigator.pop(context);
              await _shredMatch(suggestion            padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Keep'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showShredConfirmation(suggestion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VesparaColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep, size: 18),
                            SizedBox(width: 4),
                            Text('Shred'),
                          ],
                        ),
                      ),
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

  Widget _buildShredStats(Map<String, dynamic> suggestion) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VesparaColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildShredStat(
                'Messages', suggestion['messageCount']?.toString() ?? '0',),
            Container(
                width: 1,
                height: 30,
                color: VesparaColors.glow.withOpacity(0.2),),
            _buildShredStat(
                'Last Msg', '${suggestion['daysSinceLastMessage'] ?? 0}d ago',),
            Container(
                width: 1,
                height: 30,
                color: VesparaColors.glow.withOpacity(0.2),),
            _buildShredStat('Response',
                '${((suggestion['responseRate'] ?? 0.0) * 100).toInt()}%',),
          ],
        ),
      );

  Widget _buildShredStat(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      );

  void _showShredConfirmation(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: VesparaColors.error),
            const SizedBox(width: 8),
            Text('Shred ${suggestion['name']}?',
                style: const TextStyle(color: VesparaColors.primary),),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will:',
              style: TextStyle(color: VesparaColors.secondary),
            ),
            const SizedBox(height: 8),
            _buildShredConsequence('Remove them from your roster'),
            _buildShredConsequence('Archive all messages'),
            _buildShredConsequence('Cancel any scheduled dates'),
            const SizedBox(height: 16),
            const Text(
              'They won\'t be notified. This is about your energy, not theirs.',
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _shreddedHistory.add(suggestion);
                _suggestions
                    .removeWhere((s) => s['name'] == suggestion['name']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${suggestion['name']} has been shredded'),
                  backgroundColor: VesparaColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.error,
            ),
            child: const Text('Shred', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildShredConsequence(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.check, size: 14, color: VesparaColors.error),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    fontSize: 13, color: VesparaColors.primary,),),
          ],
        ),
      );

  void _showKeepDialog(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.favorite, color: VesparaColors.glow),
            const SizedBox(width: 8),
            Text('Keep ${suggestion['name']}?',
                style: const TextStyle(color: VesparaColors.primary),),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ll stop suggesting to shred this connection.',
              style: TextStyle(color: VesparaColors.secondary),
            ),
            SizedBox(height: 16),
            Text(
              'Pro tip: Maybe reach out to them today? 💬',
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.glow,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _suggestions
                    .removeWhere((s) => s['name'] == suggestion['name']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${suggestion['name']} will stay in your roster'),
                  backgroundColor: VesparaColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.glow,
            ),
            child: const Text('Keep',
                style: TextStyle(color: VesparaColors.background),),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shred History',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,),),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: VesparaColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Connections you\'ve moved on from',
                style: TextStyle(color: VesparaColors.secondary),),
            const SizedBox(height: 20),
            Expanded(
              child: _shreddedHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_delete,
                              size: 48,
                              color: VesparaColors.glow.withOpacity(0.5),),
                          const SizedBox(height: 16),
                          const Text('No shredded connections yet',
                              style: TextStyle(color: VesparaColors.secondary),),
                          const SizedBox(height: 8),
                          const Text(
                              'When you shred someone, they\'ll appear here',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: VesparaColors.secondary,),),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _shreddedHistory.length,
                      itemBuilder: (context, index) {
                        final item = _shreddedHistory[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                VesparaColors.error.withOpacity(0.3),
                            child: Text(item['name'][0],
                                style: const TextStyle(
                                    color: VesparaColors.error,),),
                          ),
                          title: Text(item['name'],
                              style: const TextStyle(
                                  color: VesparaColors.primary,),),
                          subtitle: Text(item['reason'] ?? 'No reason given',
                              style: const TextStyle(
                                  color: VesparaColors.secondary,
                                  fontSize: 12,),),
                          trailing: TextButton(
                            onPressed: () {
                              setState(() {
                                _shreddedHistory.remove(item);
                                _suggestions.add(item);
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${item['name']} restored to your roster',),
                                    backgroundColor: VesparaColors.success,),
                              );
                            },
                            child: const Text('Restore',
                                style: TextStyle(color: VesparaColors.glow),),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
