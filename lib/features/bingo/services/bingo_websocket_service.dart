import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/bingo_models.dart';
import 'bingo_realtime_service.dart';

class BingoWebSocketService implements BingoRealtimeService {
  final Uri serverUri;
  WebSocketChannel? _channel;
  final _controller = StreamController<BingoEvent>.broadcast();
  @override
  Stream<BingoEvent> get events => _controller.stream;
  final _connectedController = StreamController<bool>.broadcast();
  @override
  Stream<bool> get connected => _connectedController.stream;

  BingoWebSocketService(this.serverUri);

  @override
  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(serverUri);
      _connectedController.add(true);
      _channel!.stream.listen((message) {
        final obj = jsonDecode(message);
        final type = _parseType(obj['type'] as String?);
        if (type != null) {
          _controller.add(BingoEvent(type, obj['data'] as Map<String, dynamic>? ?? {}));
        }
      }, onError: (e) {
        _connectedController.add(false);
      }, onDone: () {
        _connectedController.add(false);
      });
    } catch (_) {
      _connectedController.add(false);
    }
  }

  BingoEventType? _parseType(String? raw) {
    switch (raw) {
      case 'drawNumber': return BingoEventType.drawNumber;
      case 'resetGame': return BingoEventType.resetGame;
      case 'setPrize': return BingoEventType.setPrize;
      case 'claimWin': return BingoEventType.claimWin;
      case 'announceWinner': return BingoEventType.announceWinner;
      case 'syncState': return BingoEventType.syncState;
    }
    return null;
  }

  @override
  void send(BingoEvent event) {
    final payload = jsonEncode({
      'type': _typeToString(event.type),
      'data': event.data,
    });
    _channel?.sink.add(payload);
  }

  String _typeToString(BingoEventType t) {
    switch (t) {
      case BingoEventType.drawNumber: return 'drawNumber';
      case BingoEventType.resetGame: return 'resetGame';
      case BingoEventType.setPrize: return 'setPrize';
      case BingoEventType.claimWin: return 'claimWin';
      case BingoEventType.announceWinner: return 'announceWinner';
      case BingoEventType.syncState: return 'syncState';
    }
  }

  @override
  Future<void> close() async {
    await _channel?.sink.close();
    await _controller.close();
    await _connectedController.close();
  }
}