import 'package:shared_preferences/shared_preferences.dart';

class MinisAnalyticsSnapshot {
  const MinisAnalyticsSnapshot({
    required this.hubVisits,
    required this.gameOpens,
    required this.gamePlays,
    required this.playsByGame,
  });

  final int hubVisits;
  final int gameOpens;
  final int gamePlays;
  final Map<String, int> playsByGame;

  String? get topGameKey {
    if (playsByGame.isEmpty) return null;

    String? winner;
    var winnerCount = -1;
    for (final entry in playsByGame.entries) {
      if (entry.value > winnerCount) {
        winner = entry.key;
        winnerCount = entry.value;
      }
    }
    return winner;
  }
}

class MinisAnalyticsService {
  MinisAnalyticsService._();
  static final MinisAnalyticsService instance = MinisAnalyticsService._();

  static const String _hubVisitsKey = 'minis_hub_visits';
  static const String _gameOpensKey = 'minis_game_opens';
  static const String _gamePlaysKey = 'minis_game_plays';
  static const String _gamePlayPrefix = 'minis_game_play_';

  static const List<String> gameKeys = <String>[
    'safe_word',
    'red_flag',
    'cocktail',
    'get_caught',
    'bad_idea',
    'whats_your_position',
  ];

  Future<void> trackHubVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_hubVisitsKey) ?? 0;
    await prefs.setInt(_hubVisitsKey, current + 1);
  }

  Future<void> trackGameOpen(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_gameOpensKey) ?? 0;
    await prefs.setInt(_gameOpensKey, current + 1);
    await prefs.setString('minis_last_opened_game', gameKey);
  }

  Future<void> trackGamePlay(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();

    final total = prefs.getInt(_gamePlaysKey) ?? 0;
    await prefs.setInt(_gamePlaysKey, total + 1);

    final perGameKey = '$_gamePlayPrefix$gameKey';
    final gameCount = prefs.getInt(perGameKey) ?? 0;
    await prefs.setInt(perGameKey, gameCount + 1);
  }

  Future<MinisAnalyticsSnapshot> getSnapshot() async {
    final prefs = await SharedPreferences.getInstance();

    final playsByGame = <String, int>{
      for (final gameKey in gameKeys)
        gameKey: prefs.getInt('$_gamePlayPrefix$gameKey') ?? 0,
    };

    return MinisAnalyticsSnapshot(
      hubVisits: prefs.getInt(_hubVisitsKey) ?? 0,
      gameOpens: prefs.getInt(_gameOpensKey) ?? 0,
      gamePlays: prefs.getInt(_gamePlaysKey) ?? 0,
      playsByGame: playsByGame,
    );
  }
}
