import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/data/vespara_mock_data.dart';

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
  late List<Map<String, dynamic>> _suggestions;
  
  @override
  void initState() {
    super.initState();
    _suggestions = MockDataProvider.shredSuggestions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
          ),
          Column(
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
            onPressed: () {},
            icon: const Icon(Icons.history, color: VesparaColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroCard(),
          const SizedBox(height: 24),
          if (_suggestions.isEmpty)
            _buildEmptyState()
          else ...[
            Text(
              'AI SUGGESTS YOU LET GO OF',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: VesparaColors.secondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ..._suggestions.map((suggestion) => _buildSuggestionCard(suggestion)),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
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
            child: Icon(
              Icons.delete_sweep,
              size: 40,
              color: VesparaColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Some connections have run their course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
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
                Icon(Icons.psychology, size: 16, color: VesparaColors.glow),
                const SizedBox(width: 8),
                Text(
                  '${_suggestions.length} connections flagged for review',
                  style: TextStyle(
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco,
            size: 80,
            color: VesparaColors.success.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'All connections look healthy!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing to shred right now. Keep nurturing your roster!',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final urgency = suggestion['urgency'] as String;
    final urgencyColor = urgency == 'high' 
        ? VesparaColors.error 
        : (urgency == 'medium' ? VesparaColors.warning : VesparaColors.secondary);
    
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                      Text(
                        'Matched ${suggestion['daysSinceMatch']} days ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    urgency.toUpperCase(),
                    style: TextStyle(
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
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: VesparaColors.glow),
                    const SizedBox(width: 8),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Stats
                _buildShredStats(suggestion),
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showKeepDialog(suggestion),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VesparaColors.glow,
                          side: BorderSide(color: VesparaColors.glow),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Keep'),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep, size: 18),
                            const SizedBox(width: 4),
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

  Widget _buildShredStats(Map<String, dynamic> suggestion) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VesparaColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildShredStat('Messages', suggestion['messageCount']?.toString() ?? '0'),
          Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
          _buildShredStat('Last Msg', '${suggestion['daysSinceLastMessage'] ?? 0}d ago'),
          Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
          _buildShredStat('Response', '${((suggestion['responseRate'] ?? 0.0) * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildShredStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: VesparaColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }

  void _showShredConfirmation(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: VesparaColors.error),
            const SizedBox(width: 8),
            Text('Shred ${suggestion['name']}?', style: TextStyle(color: VesparaColors.primary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: TextStyle(color: VesparaColors.secondary),
            ),
            const SizedBox(height: 8),
            _buildShredConsequence('Remove them from your roster'),
            _buildShredConsequence('Archive all messages'),
            _buildShredConsequence('Cancel any scheduled dates'),
            const SizedBox(height: 16),
            Text(
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
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _suggestions.removeWhere((s) => s['name'] == suggestion['name']);
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
            child: Text('Shred', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildShredConsequence(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 14, color: VesparaColors.error),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: VesparaColors.primary)),
        ],
      ),
    );
  }

  void _showKeepDialog(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.favorite, color: VesparaColors.glow),
            const SizedBox(width: 8),
            Text('Keep ${suggestion['name']}?', style: TextStyle(color: VesparaColors.primary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ll stop suggesting to shred this connection.',
              style: TextStyle(color: VesparaColors.secondary),
            ),
            const SizedBox(height: 16),
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
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _suggestions.removeWhere((s) => s['name'] == suggestion['name']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${suggestion['name']} will stay in your roster'),
                  backgroundColor: VesparaColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.glow,
            ),
            child: Text('Keep', style: TextStyle(color: VesparaColors.background)),
          ),
        ],
      ),
    );
  }
}
