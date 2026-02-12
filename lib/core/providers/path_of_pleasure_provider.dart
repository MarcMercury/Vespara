import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PATH OF PLEASURE - 1v1 COMPETITIVE KINKINESS SORTING GAME
/// Family Feud Style - Teams compete to sort cards from Vanilla to Hardcore
/// Features: Pass & Play, Multi-Screen, Dynamic Elo Rankings
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum GamePhase {
  idle, // Entry screen
  modeSelect, // Choose Pass & Play or Multi-Screen
  lobby, // Waiting for players / team setup
  sorting, // Active player sorting 8 cards
  scored, // Show score feedback (X/8 correct)
  decision, // PASS or PLAY choice
  stealing, // Other team attempting to steal
  roundResult, // Show final round result
  gameOver, // Victory screen
}

enum ConnectionMode {
  passAndPlay, // Single device, rotate between teams
  multiScreen, // Host/Client with room codes
}

enum TeamTurn {
  teamA,
  teamB,
}

enum RoundOutcome {
  perfectScore, // Team got 8/8
  playSuccess, // Team improved their score
  playFail, // Team failed to improve (0 points)
  stealSuccess, // Other team stole the points
  stealFail, // Original team keeps points
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// A single card/item to be ranked by kinkiness
class KinkCard {
  // How much it moved this week

  const KinkCard({
    required this.id,
    required this.text,
    required this.trueRank,
    this.globalRank,
    this.popularityScore,
    this.totalVotes = 0,
    this.eloScore = 1000.0,
    this.weeklyRankChange = 0,
  });

  factory KinkCard.fromJson(Map<String, dynamic> json) => KinkCard(
        id: json['id'] as String,
        text: json['text'] as String,
        trueRank: json['true_rank'] as int? ?? json['global_rank'] as int? ?? 50,
        globalRank: json['global_rank'] as int?,
        popularityScore: (json['popularity_score'] as num?)?.toDouble(),
        totalVotes: json['total_votes'] as int? ?? 0,
        eloScore: (json['elo_score'] as num?)?.toDouble() ?? 1000.0,
        weeklyRankChange: json['weekly_rank_change'] as int? ?? json['rank_change'] as int? ?? 0,
      );

  /// Create from Supabase pop_get_cards RPC result
  factory KinkCard.fromSupabase(Map<String, dynamic> json) => KinkCard(
        id: json['id'] as String,
        text: json['text'] as String,
        trueRank: json['global_rank'] as int? ?? 50,
        globalRank: json['global_rank'] as int?,
        popularityScore: (json['popularity_score'] as num?)?.toDouble(),
        totalVotes: json['total_votes'] as int? ?? 0,
        weeklyRankChange: json['rank_change'] as int? ?? 0,
      );

  final String id;
  final String text;
  final int trueRank; // 1-200 (1 = most vanilla, 200 = most hardcore)
  final int? globalRank; // Crowd-sourced rank (updated nightly)
  final double? popularityScore; // 0-100 popularity
  final int totalVotes; // How many votes this card has received
  final double eloScore; // Hidden Elo rating for crowd ranking
  final int weeklyRankChange;

  /// The effective rank used for scoring — prefers crowd-sourced globalRank,
  /// falls back to hardcoded trueRank
  int get effectiveRank => globalRank ?? trueRank;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'true_rank': trueRank,
        'global_rank': globalRank,
        'popularity_score': popularityScore,
        'total_votes': totalVotes,
        'elo_score': eloScore,
        'weekly_rank_change': weeklyRankChange,
      };
}

/// Team data
class Team {
  const Team({
    required this.name,
    required this.color,
    this.score = 0,
    this.roundsWon = 0,
  });
  final String name;
  final Color color;
  final int score;
  final int roundsWon;

  Team copyWith({String? name, Color? color, int? score, int? roundsWon}) =>
      Team(
        name: name ?? this.name,
        color: color ?? this.color,
        score: score ?? this.score,
        roundsWon: roundsWon ?? this.roundsWon,
      );
}

/// Result of a single sorting attempt
class SortResult {
  // Which positions are correct

  const SortResult({
    required this.submittedOrder,
    required this.correctOrder,
    required this.correctCount,
    required this.positionCorrect,
  });
  final List<KinkCard> submittedOrder;
  final List<KinkCard> correctOrder;
  final int correctCount; // How many are in correct position
  final List<bool> positionCorrect;

  bool get isPerfect => correctCount == 8;
}

/// Round data tracking the flow of a single round
class RoundData {
  RoundData({
    required this.cards,
    required this.correctOrder,
    this.teamAFirstAttempt,
    this.teamASecondAttempt,
    this.teamBStealAttempt,
    this.teamAChosePlay,
    this.outcome,
    this.pointsAwarded = 0,
    this.pointsAwardedTo,
  });
  final List<KinkCard> cards; // The 8 cards for this round
  final List<KinkCard> correctOrder; // Cards sorted by true rank
  SortResult? teamAFirstAttempt;
  SortResult? teamASecondAttempt; // If they chose PLAY
  SortResult? teamBStealAttempt; // If team A chose PASS
  bool? teamAChosePlay; // true = PLAY, false = PASS
  RoundOutcome? outcome;
  int pointsAwarded;
  TeamTurn? pointsAwardedTo;
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

class PathOfPleasureState {
  const PathOfPleasureState({
    this.phase = GamePhase.idle,
    this.connectionMode = ConnectionMode.passAndPlay,
    this.sessionId,
    this.roomCode,
    this.isHost = true,
    this.teamA = const Team(name: 'Team A', color: Color(0xFFFF6B6B)),
    this.teamB = const Team(name: 'Team B', color: Color(0xFF4ECDC4)),
    this.currentTurn = TeamTurn.teamA,
    this.startingTeam,
    this.winningScore = 20,
    this.cardsPerRound = 8,
    this.roundNumber = 0,
    this.currentRound,
    this.playerSorting = const [],
    this.completedRounds = const [],
    this.isLoading = false,
    this.error,
    this.showHandoffScreen = false,
    this.masterDeck = const [],
  });
  final GamePhase phase;
  final ConnectionMode connectionMode;

  // Session
  final String? sessionId;
  final String? roomCode;
  final bool isHost;

  // Teams
  final Team teamA;
  final Team teamB;
  final TeamTurn currentTurn;
  final TeamTurn? startingTeam; // Who started the current round

  // Game config
  final int winningScore;
  final int cardsPerRound;

  // Round state
  final int roundNumber;
  final RoundData? currentRound;
  final List<KinkCard> playerSorting; // Current player's sorting attempt
  final List<RoundData> completedRounds;

  // UI
  final bool isLoading;
  final String? error;
  final bool showHandoffScreen; // For Pass & Play between teams

  // Master card list
  final List<KinkCard> masterDeck;

  Team get activeTeam => currentTurn == TeamTurn.teamA ? teamA : teamB;
  Team get inactiveTeam => currentTurn == TeamTurn.teamA ? teamB : teamA;

  bool get isGameOver =>
      teamA.score >= winningScore || teamB.score >= winningScore;
  Team? get winner {
    if (teamA.score >= winningScore) return teamA;
    if (teamB.score >= winningScore) return teamB;
    return null;
  }

  PathOfPleasureState copyWith({
    GamePhase? phase,
    ConnectionMode? connectionMode,
    String? sessionId,
    bool clearSessionId = false,
    String? roomCode,
    bool clearRoomCode = false,
    bool? isHost,
    Team? teamA,
    Team? teamB,
    TeamTurn? currentTurn,
    TeamTurn? startingTeam,
    int? winningScore,
    int? cardsPerRound,
    int? roundNumber,
    RoundData? currentRound,
    bool clearCurrentRound = false,
    List<KinkCard>? playerSorting,
    List<RoundData>? completedRounds,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? showHandoffScreen,
    List<KinkCard>? masterDeck,
  }) =>
      PathOfPleasureState(
        phase: phase ?? this.phase,
        connectionMode: connectionMode ?? this.connectionMode,
        sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
        roomCode: clearRoomCode ? null : (roomCode ?? this.roomCode),
        isHost: isHost ?? this.isHost,
        teamA: teamA ?? this.teamA,
        teamB: teamB ?? this.teamB,
        currentTurn: currentTurn ?? this.currentTurn,
        startingTeam: startingTeam ?? this.startingTeam,
        winningScore: winningScore ?? this.winningScore,
        cardsPerRound: cardsPerRound ?? this.cardsPerRound,
        roundNumber: roundNumber ?? this.roundNumber,
        currentRound:
            clearCurrentRound ? null : (currentRound ?? this.currentRound),
        playerSorting: playerSorting ?? this.playerSorting,
        completedRounds: completedRounds ?? this.completedRounds,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error,
        showHandoffScreen: showHandoffScreen ?? this.showHandoffScreen,
        masterDeck: masterDeck ?? this.masterDeck,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class PathOfPleasureNotifier extends StateNotifier<PathOfPleasureState> {
  PathOfPleasureNotifier([this._supabase])
      : super(
          const PathOfPleasureState(
            masterDeck: _masterKinkCards,
          ),
        ) {
    // Attempt to load crowd-sourced cards from Supabase on init
    _loadCardsFromSupabase();
  }
  final SupabaseClient? _supabase;
  bool _cardsLoaded = false;

  // ═════════════════════════════════════════════════════════════════════════
  // SUPABASE CARD LOADING (Crowd-sourced adaptive rankings)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _loadCardsFromSupabase() async {
    if (_supabase == null || _cardsLoaded) return;

    try {
      // Fetch ALL active cards with their current global rankings
      final response = await _supabase
          .from('pop_cards')
          .select('id, text, category, subcategory, heat_level, global_rank, popularity_score, rank_change, total_votes')
          .eq('is_active', true)
          .order('global_rank', ascending: true);

      final rows = response as List<dynamic>;
      if (rows.isEmpty) return; // Keep hardcoded fallback

      final supabaseCards = rows.map((row) {
        final json = row as Map<String, dynamic>;
        return KinkCard.fromSupabase(json);
      }).toList();

      if (supabaseCards.length >= 8) {
        _cardsLoaded = true;
        state = state.copyWith(masterDeck: supabaseCards);
      }
    } catch (e) {
      // Silently fall back to hardcoded cards
      debugPrint('PathOfPleasure: Failed to load cards from Supabase: $e');
    }
  }

  /// Record votes to Supabase after a round so rankings can adapt over time.
  /// The DB auto-triggers a recalculation once enough votes accumulate
  /// (threshold-based, not schedule-based). Cards can only shift ±3 ranks
  /// per recalc cycle so rankings drift gradually.
  Future<void> _recordVotesToSupabase(List<KinkCard> submittedOrder) async {
    if (_supabase == null) return;

    try {
      final cardIds = submittedOrder.map((c) => c.id).toList();
      final positions = List.generate(submittedOrder.length, (i) => i + 1);

      await _supabase.rpc('pop_submit_round_votes', params: {
        'p_card_ids': cardIds,
        'p_submitted_positions': positions,
        'p_session_id': state.sessionId,
      });

      // Silently refresh the master deck in the background so that if a
      // recalc just fired, upcoming rounds use the latest (slightly shifted)
      // rankings. This is fire-and-forget — doesn't block gameplay.
      _refreshCardsInBackground();
    } catch (e) {
      // Non-critical — game still works, just doesn't record votes
      debugPrint('PathOfPleasure: Failed to record votes: $e');
    }
  }

  /// Quietly reload cards from Supabase without interrupting the current game.
  /// Only updates the master deck (future rounds); the current round is
  /// unaffected so no score changes mid-round.
  Future<void> _refreshCardsInBackground() async {
    if (_supabase == null) return;
    try {
      final response = await _supabase
          .from('pop_cards')
          .select('id, text, category, subcategory, heat_level, global_rank, popularity_score, rank_change, total_votes')
          .eq('is_active', true)
          .order('global_rank', ascending: true);

      final rows = response as List<dynamic>;
      if (rows.length >= 8) {
        final refreshed = rows.map((r) => KinkCard.fromSupabase(r as Map<String, dynamic>)).toList();
        state = state.copyWith(masterDeck: refreshed);
      }
    } catch (_) {
      // Ignore — current deck is fine
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SETUP & MODE SELECTION
  // ═════════════════════════════════════════════════════════════════════════

  void showModeSelect() {
    state = state.copyWith(phase: GamePhase.modeSelect);
  }

  void selectMode(ConnectionMode mode) {
    state = state.copyWith(
      connectionMode: mode,
      phase: GamePhase.lobby,
    );
  }

  void setTeamName(TeamTurn team, String name) {
    if (team == TeamTurn.teamA) {
      state = state.copyWith(teamA: state.teamA.copyWith(name: name));
    } else {
      state = state.copyWith(teamB: state.teamB.copyWith(name: name));
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MULTIPLAYER (Room Codes)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> hostMultiScreenGame() async {
    final roomCode = _generateRoomCode();
    state = state.copyWith(
      connectionMode: ConnectionMode.multiScreen,
      roomCode: roomCode,
      isHost: true,
      phase: GamePhase.lobby,
    );
    // In production: Create room in Supabase/Firebase realtime
  }

  Future<bool> joinMultiScreenGame(String code) async {
    // In production: Validate code and join room
    state = state.copyWith(
      connectionMode: ConnectionMode.multiScreen,
      roomCode: code,
      isHost: false,
      phase: GamePhase.lobby,
    );
    return true;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // GAME START
  // ═════════════════════════════════════════════════════════════════════════

  void startGame() {
    // Randomly decide who goes first
    final startingTeam = Random().nextBool() ? TeamTurn.teamA : TeamTurn.teamB;

    state = state.copyWith(
      roundNumber: 1,
      currentTurn: startingTeam,
      startingTeam: startingTeam,
      teamA: state.teamA.copyWith(score: 0, roundsWon: 0),
      teamB: state.teamB.copyWith(score: 0, roundsWon: 0),
      completedRounds: [],
    );

    _startNewRound();
  }

  void _startNewRound() {
    // Draw 8 random cards
    final shuffled = [...state.masterDeck]..shuffle();
    final roundCards = shuffled.take(8).toList();

    // Sort by effectiveRank (crowd-sourced globalRank if available, else trueRank)
    final correctOrder = [...roundCards]
      ..sort((a, b) => a.effectiveRank.compareTo(b.effectiveRank));

    final round = RoundData(
      cards: roundCards,
      correctOrder: correctOrder,
    );

    // For Pass & Play, show handoff screen
    if (state.connectionMode == ConnectionMode.passAndPlay) {
      state = state.copyWith(
        currentRound: round,
        playerSorting: [...roundCards], // Start with shuffled order
        showHandoffScreen: true,
        phase: GamePhase.sorting,
      );
    } else {
      state = state.copyWith(
        currentRound: round,
        playerSorting: [...roundCards],
        phase: GamePhase.sorting,
      );
    }
  }

  void dismissHandoff() {
    state = state.copyWith(showHandoffScreen: false);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SORTING (Drag & Drop)
  // ═════════════════════════════════════════════════════════════════════════

  void reorderCard(int oldIndex, int newIndex) {
    final cards = [...state.playerSorting];
    final card = cards.removeAt(oldIndex);
    cards.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, card);
    state = state.copyWith(playerSorting: cards);
  }

  void moveCardUp(int index) {
    if (index <= 0) return;
    reorderCard(index, index - 1);
  }

  void moveCardDown(int index) {
    if (index >= state.playerSorting.length - 1) return;
    reorderCard(index, index + 2);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SUBMISSION & SCORING
  // ═════════════════════════════════════════════════════════════════════════

  void submitSort() {
    final round = state.currentRound;
    if (round == null) return;

    final result =
        _calculateSortResult(state.playerSorting, round.correctOrder);

    // Determine which attempt this is
    if (round.teamAFirstAttempt == null) {
      // This is Team A's first attempt
      round.teamAFirstAttempt = result;

      if (result.isPerfect) {
        // Perfect score! Award 8 points immediately
        _awardPoints(8, TeamTurn.teamA, RoundOutcome.perfectScore);
      } else {
        // Show score and move to decision phase
        state = state.copyWith(
          currentRound: round,
          phase: GamePhase.scored,
        );
      }
    } else if (round.teamAChosePlay == true &&
        round.teamASecondAttempt == null) {
      // Team A chose PLAY, this is their second attempt
      round.teamASecondAttempt = result;

      final firstScore = round.teamAFirstAttempt!.correctCount;
      final secondScore = result.correctCount;

      if (secondScore > firstScore) {
        // Improved! Keep the new score
        _awardPoints(secondScore, TeamTurn.teamA, RoundOutcome.playSuccess);
      } else {
        // Failed to improve, 0 points
        _awardPoints(0, TeamTurn.teamA, RoundOutcome.playFail);
      }
    } else if (round.teamAChosePlay == false &&
        round.teamBStealAttempt == null) {
      // Team A passed, Team B is attempting to steal
      round.teamBStealAttempt = result;

      final teamAScore = round.teamAFirstAttempt!.correctCount;
      final teamBScore = result.correctCount;

      if (teamBScore > teamAScore) {
        // Steal successful!
        _awardPoints(teamBScore, TeamTurn.teamB, RoundOutcome.stealSuccess);
      } else {
        // Steal failed, Team A keeps their points
        _awardPoints(teamAScore, TeamTurn.teamA, RoundOutcome.stealFail);
      }
    }
  }

  SortResult _calculateSortResult(
      List<KinkCard> submitted, List<KinkCard> correct,) {
    final positionCorrect = <bool>[];
    int correctCount = 0;

    for (int i = 0; i < submitted.length; i++) {
      final isCorrect = submitted[i].id == correct[i].id;
      positionCorrect.add(isCorrect);
      if (isCorrect) correctCount++;
    }

    return SortResult(
      submittedOrder: submitted,
      correctOrder: correct,
      correctCount: correctCount,
      positionCorrect: positionCorrect,
    );
  }

  void _awardPoints(int points, TeamTurn team, RoundOutcome outcome) {
    final round = state.currentRound!;
    round.outcome = outcome;
    round.pointsAwarded = points;
    round.pointsAwardedTo = team;

    Team updatedTeamA = state.teamA;
    Team updatedTeamB = state.teamB;

    if (team == TeamTurn.teamA) {
      updatedTeamA = state.teamA.copyWith(
        score: state.teamA.score + points,
        roundsWon: state.teamA.roundsWon + (points > 0 ? 1 : 0),
      );
    } else {
      updatedTeamB = state.teamB.copyWith(
        score: state.teamB.score + points,
        roundsWon: state.teamB.roundsWon + (points > 0 ? 1 : 0),
      );
    }

    // Log matchups for Elo calculation (backend)
    _logMatchupsForElo(round);

    // Record votes to Supabase so crowd-sourced rankings evolve over time
    final winningSubmission = round.teamBStealAttempt?.submittedOrder ??
        round.teamASecondAttempt?.submittedOrder ??
        round.teamAFirstAttempt?.submittedOrder;
    if (winningSubmission != null) {
      _recordVotesToSupabase(winningSubmission);
    }

    state = state.copyWith(
      currentRound: round,
      teamA: updatedTeamA,
      teamB: updatedTeamB,
      completedRounds: [...state.completedRounds, round],
      phase: GamePhase.roundResult,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DECISION PHASE (PASS or PLAY)
  // ═════════════════════════════════════════════════════════════════════════

  void showDecision() {
    state = state.copyWith(phase: GamePhase.decision);
  }

  void choosePass() {
    final round = state.currentRound;
    if (round == null) return;

    round.teamAChosePlay = false;

    // Switch to Team B for steal attempt
    // In Pass & Play, show handoff
    if (state.connectionMode == ConnectionMode.passAndPlay) {
      state = state.copyWith(
        currentRound: round,
        currentTurn: TeamTurn.teamB,
        playerSorting: [
          ...round.teamAFirstAttempt!.submittedOrder,
        ], // Start with Team A's order
        showHandoffScreen: true,
        phase: GamePhase.stealing,
      );
    } else {
      state = state.copyWith(
        currentRound: round,
        currentTurn: TeamTurn.teamB,
        playerSorting: [...round.teamAFirstAttempt!.submittedOrder],
        phase: GamePhase.stealing,
      );
    }
  }

  void choosePlay() {
    final round = state.currentRound;
    if (round == null) return;

    round.teamAChosePlay = true;

    // Team A gets another chance to sort
    state = state.copyWith(
      currentRound: round,
      playerSorting: [
        ...round.teamAFirstAttempt!.submittedOrder,
      ], // Start with their previous order
      phase: GamePhase.sorting,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ROUND PROGRESSION
  // ═════════════════════════════════════════════════════════════════════════

  void continueToNextRound() {
    // Check for game over
    if (state.isGameOver) {
      state = state.copyWith(phase: GamePhase.gameOver);
      return;
    }

    // Alternate starting team
    final nextStarting =
        state.startingTeam == TeamTurn.teamA ? TeamTurn.teamB : TeamTurn.teamA;

    // Prepare new round data BEFORE updating state to avoid intermediate invalid state
    final shuffled = [...state.masterDeck]..shuffle();
    final roundCards = shuffled.take(8).toList();
    final correctOrder = [...roundCards]
      ..sort((a, b) => a.effectiveRank.compareTo(b.effectiveRank));

    final newRound = RoundData(
      cards: roundCards,
      correctOrder: correctOrder,
    );

    // Update state ONCE with all changes to prevent intermediate rebuild issues
    state = state.copyWith(
      roundNumber: state.roundNumber + 1,
      currentTurn: nextStarting,
      startingTeam: nextStarting,
      currentRound: newRound,
      playerSorting: [...roundCards],
      showHandoffScreen: state.connectionMode == ConnectionMode.passAndPlay,
      phase: GamePhase.sorting,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ELO RANKING SYSTEM (Backend Integration)
  // ═════════════════════════════════════════════════════════════════════════

  void _logMatchupsForElo(RoundData round) {
    // Get the winning submission
    List<KinkCard>? winningOrder;

    if (round.outcome == RoundOutcome.perfectScore ||
        round.outcome == RoundOutcome.playSuccess ||
        round.outcome == RoundOutcome.stealFail) {
      // Team A's submission was "correct"
      winningOrder = round.teamASecondAttempt?.submittedOrder ??
          round.teamAFirstAttempt?.submittedOrder;
    } else if (round.outcome == RoundOutcome.stealSuccess) {
      // Team B's submission was "correct"
      winningOrder = round.teamBStealAttempt?.submittedOrder;
    }

    if (winningOrder == null || _supabase == null) return;

    // Extract pairwise matchups for Elo
    // Each adjacent pair is a "vote" that card[i] < card[i+1]
    final matchups = <Map<String, String>>[];
    for (int i = 0; i < winningOrder.length - 1; i++) {
      matchups.add({
        'less_kinky_id': winningOrder[i].id,
        'more_kinky_id': winningOrder[i + 1].id,
      });
    }

    // Log to backend (async, fire and forget)
    _supabase
        .from('pop_elo_matchups')
        .insert({
          'session_id': state.sessionId,
          'matchups': matchups,
          'created_at': DateTime.now().toIso8601String(),
        })
        .then((_) {})
        .catchError((_) {});
  }

  // ═════════════════════════════════════════════════════════════════════════
  // RESET
  // ═════════════════════════════════════════════════════════════════════════

  void reset() {
    state = const PathOfPleasureState(masterDeck: _masterKinkCards);
  }

  void backToLobby() {
    state = state.copyWith(
      phase: GamePhase.lobby,
      roundNumber: 0,
      completedRounds: [],
      teamA: state.teamA.copyWith(score: 0, roundsWon: 0),
      teamB: state.teamB.copyWith(score: 0, roundsWon: 0),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final pathOfPleasureProvider =
    StateNotifierProvider<PathOfPleasureNotifier, PathOfPleasureState>(
  (ref) {
    try {
      return PathOfPleasureNotifier(Supabase.instance.client);
    } catch (_) {
      return PathOfPleasureNotifier();
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// MASTER CARD LIST - 200 Items Ranked by Kinkiness (1 = Vanilla, 200 = Hardcore)
// ═══════════════════════════════════════════════════════════════════════════

const List<KinkCard> _masterKinkCards = [
  // VANILLA (1-40) - Sweet, innocent, universally loved
  KinkCard(id: 'k001', text: 'Holding hands', trueRank: 1),
  KinkCard(id: 'k002', text: 'Forehead kisses', trueRank: 2),
  KinkCard(id: 'k003', text: 'Cuddling', trueRank: 3),
  KinkCard(id: 'k004', text: 'Hugging from behind', trueRank: 4),
  KinkCard(id: 'k005', text: 'Butterfly kisses', trueRank: 5),
  KinkCard(id: 'k006', text: 'Slow dancing', trueRank: 6),
  KinkCard(id: 'k007', text: 'Spooning', trueRank: 7),
  KinkCard(id: 'k008', text: 'Morning cuddles', trueRank: 8),
  KinkCard(id: 'k009', text: 'Hand on the small of back', trueRank: 9),
  KinkCard(id: 'k010', text: 'Playing with hair', trueRank: 10),
  KinkCard(id: 'k011', text: 'Watching sunset together', trueRank: 11),
  KinkCard(id: 'k012', text: 'Cooking together', trueRank: 12),
  KinkCard(id: 'k013', text: 'Falling asleep on their chest', trueRank: 13),
  KinkCard(id: 'k014', text: 'Long goodbye hugs', trueRank: 14),
  KinkCard(id: 'k015', text: 'Nose kisses', trueRank: 15),
  KinkCard(id: 'k016', text: 'Stargazing', trueRank: 16),
  KinkCard(id: 'k017', text: 'Sharing a blanket', trueRank: 17),
  KinkCard(id: 'k018', text: 'Whispering sweet nothings', trueRank: 18),
  KinkCard(id: 'k019', text: 'Bubble bath together', trueRank: 19),
  KinkCard(id: 'k020', text: 'Massage (non-sexual)', trueRank: 20),
  KinkCard(id: 'k021', text: 'French kissing', trueRank: 21),
  KinkCard(id: 'k022', text: 'Making out', trueRank: 22),
  KinkCard(id: 'k023', text: 'Hickeys', trueRank: 23),
  KinkCard(id: 'k024', text: 'Neck kisses', trueRank: 24),
  KinkCard(id: 'k025', text: 'Ear nibbling', trueRank: 25),
  KinkCard(id: 'k026', text: 'Skinny dipping', trueRank: 26),
  KinkCard(id: 'k027', text: 'Sleeping naked together', trueRank: 27),
  KinkCard(id: 'k028', text: 'Strip poker', trueRank: 28),
  KinkCard(id: 'k029', text: 'Body massage with oil', trueRank: 29),
  KinkCard(id: 'k030', text: 'Netflix and Chill', trueRank: 30),
  KinkCard(id: 'k031', text: 'Lap sitting', trueRank: 31),
  KinkCard(id: 'k032', text: 'Grinding (clothed)', trueRank: 32),
  KinkCard(id: 'k033', text: 'Dry humping', trueRank: 33),
  KinkCard(id: 'k034', text: 'Teasing touches', trueRank: 34),
  KinkCard(id: 'k035', text: 'Whispering fantasies', trueRank: 35),
  KinkCard(id: 'k036', text: 'Sexting', trueRank: 36),
  KinkCard(id: 'k037', text: 'Phone sex', trueRank: 37),
  KinkCard(id: 'k038', text: 'Video call striptease', trueRank: 38),
  KinkCard(id: 'k039', text: 'Sending nudes', trueRank: 39),
  KinkCard(id: 'k040', text: 'Receiving nudes', trueRank: 40),

  // MILD (41-80) - Getting warmer, mainstream intimacy
  KinkCard(id: 'k041', text: 'Missionary', trueRank: 41),
  KinkCard(id: 'k042', text: 'Cowgirl', trueRank: 42),
  KinkCard(id: 'k043', text: 'Reverse cowgirl', trueRank: 43),
  KinkCard(id: 'k044', text: 'Doggy style', trueRank: 44),
  KinkCard(id: 'k045', text: 'Spooning sex', trueRank: 45),
  KinkCard(id: 'k046', text: 'Morning sex', trueRank: 46),
  KinkCard(id: 'k047', text: 'Quickie', trueRank: 47),
  KinkCard(id: 'k048', text: 'Shower sex', trueRank: 48),
  KinkCard(id: 'k049', text: 'Bath sex', trueRank: 49),
  KinkCard(id: 'k050', text: 'Hand job', trueRank: 50),
  KinkCard(id: 'k051', text: 'Fingering', trueRank: 51),
  KinkCard(id: 'k052', text: 'Blow job', trueRank: 52),
  KinkCard(id: 'k053', text: 'Going down on her', trueRank: 53),
  KinkCard(id: 'k054', text: 'Mutual masturbation', trueRank: 54),
  KinkCard(id: 'k055', text: '69', trueRank: 55),
  KinkCard(id: 'k056', text: 'Using a vibrator together', trueRank: 56),
  KinkCard(id: 'k057', text: 'Dirty talk', trueRank: 57),
  KinkCard(id: 'k058', text: 'Moaning loudly', trueRank: 58),
  KinkCard(id: 'k059', text: 'Hair pulling', trueRank: 59),
  KinkCard(id: 'k060', text: 'Light scratching', trueRank: 60),
  KinkCard(id: 'k061', text: 'Biting (gentle)', trueRank: 61),
  KinkCard(id: 'k062', text: 'Spanking (playful)', trueRank: 62),
  KinkCard(id: 'k063', text: 'Using ice cubes', trueRank: 63),
  KinkCard(id: 'k064', text: 'Whipped cream', trueRank: 64),
  KinkCard(id: 'k065', text: 'Chocolate body paint', trueRank: 65),
  KinkCard(id: 'k066', text: 'Feather tickler', trueRank: 66),
  KinkCard(id: 'k067', text: 'Silk blindfold', trueRank: 67),
  KinkCard(id: 'k068', text: 'Fuzzy handcuffs', trueRank: 68),
  KinkCard(id: 'k069', text: 'Strip tease', trueRank: 69),
  KinkCard(id: 'k070', text: 'Lap dance', trueRank: 70),
  KinkCard(id: 'k071', text: 'Role play (light)', trueRank: 71),
  KinkCard(id: 'k072', text: 'Sexy lingerie', trueRank: 72),
  KinkCard(id: 'k073', text: 'Costumes', trueRank: 73),
  KinkCard(id: 'k074', text: 'Mirror watching', trueRank: 74),
  KinkCard(id: 'k075', text: 'Sex on the couch', trueRank: 75),
  KinkCard(id: 'k076', text: 'Kitchen counter sex', trueRank: 76),
  KinkCard(id: 'k077', text: 'Against the wall', trueRank: 77),
  KinkCard(id: 'k078', text: 'Balcony/patio', trueRank: 78),
  KinkCard(id: 'k079', text: 'Hotel room adventure', trueRank: 79),
  KinkCard(id: 'k080', text: 'Car sex', trueRank: 80),

  // SPICY (81-120) - Adventurous, requires communication
  KinkCard(id: 'k081', text: 'Deep throat', trueRank: 81),
  KinkCard(id: 'k082', text: 'Face sitting', trueRank: 82),
  KinkCard(id: 'k083', text: 'Edging', trueRank: 83),
  KinkCard(id: 'k084', text: 'Orgasm denial', trueRank: 84),
  KinkCard(id: 'k085', text: 'Multiple orgasms', trueRank: 85),
  KinkCard(id: 'k086', text: 'Squirting', trueRank: 86),
  KinkCard(id: 'k087', text: 'Cream pie', trueRank: 87),
  KinkCard(id: 'k088', text: 'Facial', trueRank: 88),
  KinkCard(id: 'k089', text: 'Swallowing', trueRank: 89),
  KinkCard(id: 'k090', text: 'Tit fucking', trueRank: 90),
  KinkCard(id: 'k091', text: 'Prostate massage', trueRank: 91),
  KinkCard(id: 'k092', text: 'Rimming', trueRank: 92),
  KinkCard(id: 'k093', text: 'Anal play (fingers)', trueRank: 93),
  KinkCard(id: 'k094', text: 'Butt plug', trueRank: 94),
  KinkCard(id: 'k095', text: 'Anal beads', trueRank: 95),
  KinkCard(id: 'k096', text: 'Anal sex', trueRank: 96),
  KinkCard(id: 'k097', text: 'Double penetration (toys)', trueRank: 97),
  KinkCard(id: 'k098', text: 'Bondage (light)', trueRank: 98),
  KinkCard(id: 'k099', text: 'Handcuffs (real)', trueRank: 99),
  KinkCard(id: 'k100', text: 'Rope bondage', trueRank: 100),
  KinkCard(id: 'k101', text: 'Shibari', trueRank: 101),
  KinkCard(id: 'k102', text: 'Blindfolded (full)', trueRank: 102),
  KinkCard(id: 'k103', text: 'Sensory deprivation', trueRank: 103),
  KinkCard(id: 'k104', text: 'Wax play', trueRank: 104),
  KinkCard(id: 'k105', text: 'Impact play (spanking)', trueRank: 105),
  KinkCard(id: 'k106', text: 'Paddle', trueRank: 106),
  KinkCard(id: 'k107', text: 'Flogger', trueRank: 107),
  KinkCard(id: 'k108', text: 'Riding crop', trueRank: 108),
  KinkCard(id: 'k109', text: 'Nipple clamps', trueRank: 109),
  KinkCard(id: 'k110', text: 'Cock ring', trueRank: 110),
  KinkCard(id: 'k111', text: 'Collar and leash', trueRank: 111),
  KinkCard(id: 'k112', text: 'Dom/sub dynamic', trueRank: 112),
  KinkCard(id: 'k113', text: 'Praise kink', trueRank: 113),
  KinkCard(id: 'k114', text: 'Degradation (consensual)', trueRank: 114),
  KinkCard(id: 'k115', text: 'Daddy/Mommy kink', trueRank: 115),
  KinkCard(id: 'k116', text: 'Brat taming', trueRank: 116),
  KinkCard(id: 'k117', text: 'Aftercare', trueRank: 117),
  KinkCard(id: 'k118', text: 'Safe words', trueRank: 118),
  KinkCard(id: 'k119', text: 'Role play (intense)', trueRank: 119),
  KinkCard(id: 'k120', text: 'Public teasing', trueRank: 120),

  // HOT (121-160) - Advanced, requires trust & experience
  KinkCard(id: 'k121', text: 'Sex in public (risky)', trueRank: 121),
  KinkCard(id: 'k122', text: 'Mile high club', trueRank: 122),
  KinkCard(id: 'k123', text: 'Exhibitionism', trueRank: 123),
  KinkCard(id: 'k124', text: 'Voyeurism', trueRank: 124),
  KinkCard(id: 'k125', text: 'Recording (private)', trueRank: 125),
  KinkCard(id: 'k126', text: 'Sex tape', trueRank: 126),
  KinkCard(id: 'k127', text: 'Remote control vibrator (public)', trueRank: 127),
  KinkCard(id: 'k128', text: 'Glory hole fantasy', trueRank: 128),
  KinkCard(id: 'k129', text: 'Threesome fantasy', trueRank: 129),
  KinkCard(id: 'k130', text: 'MFF threesome', trueRank: 130),
  KinkCard(id: 'k131', text: 'MMF threesome', trueRank: 131),
  KinkCard(id: 'k132', text: 'Cuckolding fantasy', trueRank: 132),
  KinkCard(id: 'k133', text: 'Hotwife', trueRank: 133),
  KinkCard(id: 'k134', text: 'Swinging (soft swap)', trueRank: 134),
  KinkCard(id: 'k135', text: 'Swinging (full swap)', trueRank: 135),
  KinkCard(id: 'k136', text: 'Open relationship', trueRank: 136),
  KinkCard(id: 'k137', text: 'Polyamory', trueRank: 137),
  KinkCard(id: 'k138', text: 'Unicorn hunting', trueRank: 138),
  KinkCard(id: 'k139', text: 'Sex club visit', trueRank: 139),
  KinkCard(id: 'k140', text: 'Dungeon experience', trueRank: 140),
  KinkCard(id: 'k141', text: 'Pegging', trueRank: 141),
  KinkCard(id: 'k142', text: 'Strap-on', trueRank: 142),
  KinkCard(id: 'k143', text: 'Double-sided dildo', trueRank: 143),
  KinkCard(id: 'k144', text: 'Fucking machine', trueRank: 144),
  KinkCard(id: 'k145', text: 'Sex swing', trueRank: 145),
  KinkCard(id: 'k146', text: 'Suspension bondage', trueRank: 146),
  KinkCard(id: 'k147', text: 'Spreader bar', trueRank: 147),
  KinkCard(id: 'k148', text: 'Ball gag', trueRank: 148),
  KinkCard(id: 'k149', text: 'Chastity cage', trueRank: 149),
  KinkCard(id: 'k150', text: 'Orgasm torture', trueRank: 150),
  KinkCard(id: 'k151', text: 'Femdom', trueRank: 151),
  KinkCard(id: 'k152', text: 'Findom', trueRank: 152),
  KinkCard(id: 'k153', text: 'Foot worship', trueRank: 153),
  KinkCard(id: 'k154', text: 'Foot job', trueRank: 154),
  KinkCard(id: 'k155', text: 'Body worship', trueRank: 155),
  KinkCard(id: 'k156', text: 'Free use', trueRank: 156),
  KinkCard(id: 'k157', text: 'CNC', trueRank: 157),
  KinkCard(id: 'k158', text: 'Breeding kink', trueRank: 158),
  KinkCard(id: 'k159', text: 'Impregnation fantasy', trueRank: 159),
  KinkCard(id: 'k160', text: 'Lactation', trueRank: 160),

  // HARDCORE (161-200) - Extreme, niche, requires expertise
  KinkCard(id: 'k161', text: 'Gang bang fantasy', trueRank: 161),
  KinkCard(id: 'k162', text: 'Bukkake', trueRank: 162),
  KinkCard(id: 'k163', text: 'Double penetration (real)', trueRank: 163),
  KinkCard(id: 'k164', text: 'Fisting', trueRank: 164),
  KinkCard(id: 'k165', text: 'Sounding', trueRank: 165),
  KinkCard(id: 'k166', text: 'CBT', trueRank: 166),
  KinkCard(id: 'k167', text: 'Ball stretcher', trueRank: 167),
  KinkCard(id: 'k168', text: 'Electro play', trueRank: 168),
  KinkCard(id: 'k169', text: 'Violet wand', trueRank: 169),
  KinkCard(id: 'k170', text: 'Needle play', trueRank: 170),
  KinkCard(id: 'k171', text: 'Blood play', trueRank: 171),
  KinkCard(id: 'k172', text: 'Knife play', trueRank: 172),
  KinkCard(id: 'k173', text: 'Fire play', trueRank: 173),
  KinkCard(id: 'k174', text: 'Breath play', trueRank: 174),
  KinkCard(id: 'k175', text: 'Choking (intense)', trueRank: 175),
  KinkCard(id: 'k176', text: 'Face slapping', trueRank: 176),
  KinkCard(id: 'k177', text: 'Spitting', trueRank: 177),
  KinkCard(id: 'k178', text: 'Golden shower', trueRank: 178),
  KinkCard(id: 'k179', text: 'Scat', trueRank: 179),
  KinkCard(id: 'k180', text: 'Enema', trueRank: 180),
  KinkCard(id: 'k181', text: 'Medical play', trueRank: 181),
  KinkCard(id: 'k182', text: 'Speculum', trueRank: 182),
  KinkCard(id: 'k183', text: 'Age play', trueRank: 183),
  KinkCard(id: 'k184', text: 'Pet play', trueRank: 184),
  KinkCard(id: 'k185', text: 'Pony play', trueRank: 185),
  KinkCard(id: 'k186', text: 'Puppy play', trueRank: 186),
  KinkCard(id: 'k187', text: 'Furry', trueRank: 187),
  KinkCard(id: 'k188', text: 'Latex/rubber', trueRank: 188),
  KinkCard(id: 'k189', text: 'Gimp suit', trueRank: 189),
  KinkCard(id: 'k190', text: 'Mummification', trueRank: 190),
  KinkCard(id: 'k191', text: 'Sensory isolation', trueRank: 191),
  KinkCard(id: 'k192', text: 'Total power exchange', trueRank: 192),
  KinkCard(id: 'k193', text: '24/7 D/s', trueRank: 193),
  KinkCard(id: 'k194', text: 'Slave contract', trueRank: 194),
  KinkCard(id: 'k195', text: 'Humiliation (public)', trueRank: 195),
  KinkCard(id: 'k196', text: 'Forced feminization', trueRank: 196),
  KinkCard(id: 'k197', text: 'Sissy training', trueRank: 197),
  KinkCard(id: 'k198', text: 'Objectification', trueRank: 198),
  KinkCard(id: 'k199', text: 'Human furniture', trueRank: 199),
  KinkCard(id: 'k200', text: 'Edge play (extreme)', trueRank: 200),
];
