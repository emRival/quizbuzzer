import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef ClientMessageHandler = void Function(String clientId, Map<String, dynamic> message);
typedef ClientConnectHandler = void Function(String clientId, String clientName);
typedef ClientDisconnectHandler = void Function(String clientId);
typedef BroadcastHandler = void Function(Map<String, dynamic> message);

enum GameState { waiting, playing, finished }

class ServerService {
  HttpServer? _server;
  final Map<String, WebSocketChannel> _clients = {};
  final Map<String, String> _clientNames = {};
  final Map<String, int> _scores = {};
  bool _isLocked = false;
  String? _winnerName;
  int _port = 8080;
  String _ipAddress = '';
  final int maxParticipants;
  GameState _gameState = GameState.waiting;

  ServerService({this.maxParticipants = 50});

  ClientMessageHandler? onClientMessage;
  ClientConnectHandler? onClientConnect;
  ClientDisconnectHandler? onClientDisconnect;
  BroadcastHandler? onBroadcast;

  bool get isLocked => _isLocked;
  String? get winnerName => _winnerName;
  int get port => _port;
  String get ipAddress => _ipAddress;
  List<String> get connectedClientIds => _clients.keys.toList();
  Map<String, String> get clientNames => Map.unmodifiable(_clientNames);
  Map<String, int> get scores => Map.unmodifiable(_scores);
  GameState get gameState => _gameState;

  Future<void> start(int port, String assetsPath) async {
    _port = port;
    final ip = await _getLocalIp();
    _ipAddress = ip.isNotEmpty ? ip : '0.0.0.0';

    final staticHandler = createStaticHandler(
      assetsPath,
      defaultDocument: 'index.html',
    );

    final wsHandler = webSocketHandler(
      (WebSocketChannel channel, String? protocol) {
        _handleWebSocket(channel);
      },
    );

    final router = Router()
      ..get('/ws', wsHandler)
      ..get('/<path|.*>', staticHandler);

    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler(router.call);

    _server = await shelf_io.serve(pipeline, '0.0.0.0', port);
    print('Server started on http://$_ipAddress:$port');
  }

  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': '*',
  };

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      
      // 1. Prioritize physical Wi-Fi/Ethernet interface 'en0' or 'en1' on macOS
      for (final interface in interfaces) {
        if (interface.name == 'en0' || interface.name == 'en1') {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              return addr.address;
            }
          }
        }
      }

      // 2. Prioritize standard local network subnets (192.168.x.x or 10.x.x.x)
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final ipStr = addr.address;
            if (ipStr.startsWith('192.168.') || ipStr.startsWith('10.')) {
              return ipStr;
            }
          }
        }
      }

      // 3. Fallback to any active IPv4 interface
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }

  void _handleWebSocket(WebSocketChannel channel) {
    final clientId = DateTime.now().millisecondsSinceEpoch.toString() + channel.hashCode.toString();
    _clients[clientId] = channel;

    channel.stream.listen(
      (message) => _handleWebSocketMessage(clientId, message),
      onDone: () => _handleClientDisconnect(clientId),
      onError: (e) => _handleClientDisconnect(clientId),
    );
  }

  void _handleWebSocketMessage(String clientId, dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final action = data['action'] as String?;

      switch (action) {
        case 'join':
          // Jika game sedang playing, tidak ada yang bisa join
          if (_gameState == GameState.playing) {
            final channel = _clients[clientId];
            channel?.sink.add(jsonEncode({
              'status': 'error',
              'winner': null,
              'message': 'Game sudah mulai! Tunggu reset.',
            }));
            return;
          }
          
          if (_clientNames.length >= maxParticipants) {
            final channel = _clients[clientId];
            channel?.sink.add(jsonEncode({
              'status': 'full',
              'winner': null,
              'message': 'Room is full!',
            }));
            return;
          }
          final name = data['name'] as String? ?? 'Unknown';
          if (_clientNames.containsValue(name)) {
            final channel = _clients[clientId];
            channel?.sink.add(jsonEncode({
              'status': 'error',
              'winner': null,
              'message': 'Name already taken!',
            }));
            return;
          }
          _clientNames[clientId] = name;
          _scores.putIfAbsent(name, () => 0);
          onClientConnect?.call(clientId, name);
          
          // Kirim status ke semua player
          if (_gameState == GameState.waiting) {
            _broadcast({
              'status': 'waiting',
              'gameState': 'waiting',
              'winner': _winnerName,
              'message': 'Tunggu host klik Play!',
              'timer': null,
            });
          } else if (_gameState == GameState.playing) {
            _broadcast({
              'status': 'playing',
              'gameState': 'playing',
              'winner': null,
              'message': 'Game sedang berlangsung!',
              'timer': null,
            });
          } else {
            _broadcast({
              'status': 'finished',
              'gameState': 'finished',
              'winner': _winnerName,
              'message': _winnerName != null ? '🔥 $_winnerName WINNER! 🔥' : 'Tunggu reset!',
              'timer': null,
            });
          }
          break;
          
        case 'buzz':
          // Hanya bisa buzz kalau playing dan timer selesai dan tidak locked
          if (_gameState != GameState.playing) {
            return;
          }
          if (_isLocked) {
            return;
          }
          _isLocked = true;
          _gameState = GameState.finished;
          _winnerName = _clientNames[clientId] ?? 'Unknown';
          onClientMessage?.call(clientId, data);
          _broadcast({
            'status': 'locked',
            'winner': _winnerName,
            'message': '🔥 $_winnerName BUZZED IN! 🔥',
          });
          break;
      }
    } catch (e) {
      // ignore malformed messages
    }
  }

  void _handleClientDisconnect(String clientId) {
    _clients.remove(clientId);
    _clientNames.remove(clientId);
    onClientDisconnect?.call(clientId);
  }

  void _broadcast(Map<String, dynamic> message) {
    final fullMessage = Map<String, dynamic>.from(message);
    fullMessage['players'] = _clientNames.values.toList();
    fullMessage['scores'] = _scores;

    final json = jsonEncode(fullMessage);
    for (final channel in _clients.values) {
      channel.sink.add(json);
    }
    onBroadcast?.call(fullMessage);
  }

  void incrementScore(String name) {
    _scores[name] = (_scores[name] ?? 0) + 1;
    _broadcastState();
  }

  void decrementScore(String name) {
    _scores[name] = (_scores[name] ?? 0) - 1;
    _broadcastState();
  }

  void resetScores() {
    _scores.clear();
    for (final name in _clientNames.values) {
      _scores[name] = 0;
    }
    _broadcastState();
  }

  void kickPlayer(String name) {
    String? foundClientId;
    _clientNames.forEach((clientId, clientName) {
      if (clientName == name) {
        foundClientId = clientId;
      }
    });

    if (foundClientId != null) {
      final channel = _clients[foundClientId];
      channel?.sink.add(jsonEncode({
        'status': 'error',
        'message': 'Anda telah dikeluarakan oleh Host!',
      }));
      channel?.sink.close();
      _clients.remove(foundClientId);
      _clientNames.remove(foundClientId);
      _scores.remove(name);
      _handleClientDisconnect(foundClientId!);
    }
  }

  void unlockBuzzer([int timerSeconds = 0]) {
    _isLocked = false;
    _winnerName = null;
    _gameState = GameState.playing;
    _broadcast({
      'status': 'playing',
      'gameState': 'playing',
      'winner': null,
      'message': timerSeconds > 0 ? 'Buzzer dibuka kembali! Bersiaplah...' : 'Buzzer dibuka kembali! Buzz sekarang!',
      'timer': timerSeconds,
    });
  }

  void _broadcastState() {
    _broadcast({
      'status': _isLocked ? 'locked' : (_gameState == GameState.playing ? 'playing' : 'waiting'),
      'gameState': _gameState == GameState.playing ? 'playing' : (_gameState == GameState.finished ? 'finished' : 'waiting'),
      'winner': _winnerName,
      'message': _isLocked 
          ? '🔥 $_winnerName BUZZED IN! 🔥' 
          : (_gameState == GameState.playing ? 'GO! Buzz sekarang!' : 'Tunggu host klik Play!'),
    });
  }

  void startGame(int timerSeconds) {
    _gameState = GameState.playing;
    _isLocked = false;
    _winnerName = null;
    
    if (timerSeconds > 0) {
      _broadcast({
        'status': 'playing',
        'gameState': 'playing',
        'winner': null,
        'message': 'GO! Buzz sekarang!',
        'timer': timerSeconds,
      });
    } else {
      _broadcast({
        'status': 'playing',
        'gameState': 'playing',
        'winner': null,
        'message': 'GO! Buzz sekarang!',
        'timer': 0,
      });
    }
  }

  void resetGame() {
    _gameState = GameState.waiting;
    _isLocked = false;
    _winnerName = null;
    _broadcast({
      'status': 'waiting',
      'gameState': 'waiting',
      'winner': null,
      'message': 'Game direset! Siap join lagi!',
      'timer': null,
    });
  }

  void stopGame() {
    _gameState = GameState.waiting;
    _isLocked = false;
    _winnerName = null;
    _broadcast({
      'status': 'waiting',
      'gameState': 'waiting',
      'winner': null,
      'message': 'Buzzer reset! Go again!',
      'timer': null,
    });
  }

  void reset() {
    _gameState = GameState.waiting;
    _isLocked = false;
    _winnerName = null;
    _broadcast({
      'status': 'waiting',
      'gameState': 'waiting',
      'winner': null,
      'message': 'Buzzer reset! Go again!',
      'timer': null,
    });
  }

  Future<void> stop() async {
    for (final channel in _clients.values) {
      channel.sink.close();
    }
    _clients.clear();
    _clientNames.clear();
    await _server?.close();
    _server = null;
    _isLocked = false;
    _winnerName = null;
    _gameState = GameState.waiting;
  }
}