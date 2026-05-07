import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/server_service.dart';

class QuizSettings {
  final int maxParticipants;
  final int timerSeconds;

  const QuizSettings({
    this.maxParticipants = 50,
    this.timerSeconds = 0,
  });

  QuizSettings copyWith({
    int? maxParticipants,
    int? timerSeconds,
  }) {
    return QuizSettings(
      maxParticipants: maxParticipants ?? this.maxParticipants,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }
}

class QuizState {
  final bool isLocked;
  final String? winnerName;
  final List<String> connectedUsers;
  final Map<String, int> scores;
  final String? serverUrl;
  final bool isServerRunning;
  final bool isPlaying;
  final String? error;
  final QuizSettings settings;
  final int? timerRemaining;

  const QuizState({
    this.isLocked = false,
    this.winnerName,
    this.connectedUsers = const [],
    this.scores = const {},
    this.serverUrl,
    this.isServerRunning = false,
    this.isPlaying = false,
    this.error,
    this.settings = const QuizSettings(),
    this.timerRemaining,
  });

  QuizState copyWith({
    bool? isLocked,
    String? winnerName,
    bool clearWinner = false,
    List<String>? connectedUsers,
    Map<String, int>? scores,
    String? serverUrl,
    bool? isServerRunning,
    bool? isPlaying,
    String? error,
    bool clearError = false,
    QuizSettings? settings,
    int? timerRemaining,
    bool clearTimer = false,
  }) {
    return QuizState(
      isLocked: isLocked ?? this.isLocked,
      winnerName: clearWinner ? null : (winnerName ?? this.winnerName),
      connectedUsers: connectedUsers ?? this.connectedUsers,
      scores: scores ?? this.scores,
      serverUrl: serverUrl ?? this.serverUrl,
      isServerRunning: isServerRunning ?? this.isServerRunning,
      isPlaying: isPlaying ?? this.isPlaying,
      error: clearError ? null : (error ?? this.error),
      settings: settings ?? this.settings,
      timerRemaining: clearTimer ? null : (timerRemaining ?? this.timerRemaining),
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  ServerService? _serverService;
  Timer? _buzzTimer;

  QuizNotifier() : super(const QuizState());

  Future<void> startServer(int port, String assetsPath, QuizSettings settings) async {
    try {
      final server = ServerService(maxParticipants: settings.maxParticipants);
      
      server.onClientConnect = (clientId, name) {
        final users = List<String>.from(state.connectedUsers);
        if (!users.contains(name)) {
          users.add(name);
        }
        final Map<String, int> currentScores = Map<String, int>.from(state.scores);
        currentScores.putIfAbsent(name, () => 0);
        state = state.copyWith(connectedUsers: users, scores: currentScores);
      };

      server.onClientDisconnect = (clientId) {
        final server = _serverService;
        if (server != null) {
          final users = server.clientNames.values.toList();
          state = state.copyWith(connectedUsers: users);
        }
      };

      server.onClientMessage = (clientId, message) {
        final winner = server.winnerName;
        if (winner != null) {
          _buzzTimer?.cancel();
          _buzzTimer = null;
          state = state.copyWith(
            isLocked: true,
            winnerName: winner,
            isPlaying: false,
            clearTimer: true,
          );
        }
      };

      server.onBroadcast = (message) {
        final status = message['status'] as String?;
        final gameState = message['gameState'] as String?;
        final List<String> players = List<String>.from(message['players'] ?? []);
        final Map<String, int> scores = Map<String, int>.from(message['scores'] ?? {});

        if (status == 'playing' || gameState == 'playing') {
          final timer = state.settings.timerSeconds;
          if (timer != null && timer > 0 && !state.isPlaying) {
            _startTimer(timer);
          }
          state = state.copyWith(
            isPlaying: true,
            isLocked: false,
            connectedUsers: players,
            scores: scores,
          );
        } else if (status == 'locked') {
          state = state.copyWith(
            isLocked: true,
            isPlaying: false,
            connectedUsers: players,
            scores: scores,
          );
        } else if (status == 'waiting' || gameState == 'waiting') {
          state = state.copyWith(
            isPlaying: false,
            isLocked: false,
            connectedUsers: players,
            scores: scores,
            timerRemaining: null,
          );
        } else {
          state = state.copyWith(
            connectedUsers: players,
            scores: scores,
          );
        }
      };

      await server.start(port, assetsPath);
      _serverService = server;

      state = state.copyWith(
        serverUrl: 'http://${server.ipAddress}:${server.port}',
        isServerRunning: true,
        isPlaying: false,
        isLocked: false,
        winnerName: null,
        connectedUsers: [],
        settings: settings,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void play() {
    if (_serverService != null && !state.isPlaying && !state.isLocked) {
      _serverService!.startGame(state.settings.timerSeconds);
      state = state.copyWith(
        isPlaying: true,
        isLocked: false,
      );
    }
  }

  void _startTimer(int seconds) {
    _buzzTimer?.cancel();
    state = state.copyWith(timerRemaining: seconds);
    _buzzTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.timerRemaining ?? 0;
      if (remaining <= 1) {
        timer.cancel();
        _buzzTimer = null;
        state = state.copyWith(clearTimer: true);
      } else {
        state = state.copyWith(timerRemaining: remaining - 1);
      }
    });
  }

  void reset() {
    _buzzTimer?.cancel();
    _buzzTimer = null;
    _serverService?.resetGame();
    state = state.copyWith(
      isPlaying: false,
      isLocked: false,
      clearWinner: true,
    );
  }

  Future<void> stopServer() async {
    _buzzTimer?.cancel();
    _buzzTimer = null;
    await _serverService?.stop();
    _serverService = null;
    state = state.copyWith(
      isServerRunning: false,
      isPlaying: false,
      isLocked: false,
      clearWinner: true,
      serverUrl: null,
      connectedUsers: [],
      clearTimer: true,
    );
  }

  void addPoint(String name) {
    _serverService?.incrementScore(name);
  }

  void subtractPoint(String name) {
    _serverService?.decrementScore(name);
  }

  void resetScores() {
    _serverService?.resetScores();
  }

  void kickPlayer(String name) {
    _serverService?.kickPlayer(name);
    // Refresh local list
    final users = List<String>.from(state.connectedUsers)..remove(name);
    final scores = Map<String, int>.from(state.scores)..remove(name);
    state = state.copyWith(connectedUsers: users, scores: scores);
  }

  void unlockBuzzer() {
    _buzzTimer?.cancel();
    _buzzTimer = null;
    final timerSeconds = state.settings.timerSeconds;
    _serverService?.unlockBuzzer(timerSeconds);
    state = state.copyWith(
      isPlaying: true,
      isLocked: false,
      clearWinner: true,
    );
  }

  @override
  void dispose() {
    _buzzTimer?.cancel();
    _serverService?.stop();
    super.dispose();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});