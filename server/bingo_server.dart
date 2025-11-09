import 'dart:async';
import 'dart:convert';
import 'dart:io';

class Client {
  final WebSocket socket;
  Client(this.socket);
}

Future<void> main(List<String> args) async {
  final address = InternetAddress.loopbackIPv4;
  const port = 8080;
  final server = await HttpServer.bind(address, port);
  print('Bingo WebSocket server running at ws://${address.address}:$port/ws');

  final clients = <Client>{};
  Map<String, dynamic>? currentPrize; // {'id':..., 'title':..., 'imageUrl':...}
  final winners = <String>[];
  final drawnNumbers = <int>[];

  // Simple file persistence
  final stateFile = File('bingo_state.json');
  Future<void> saveState() async {
    try {
      final json = jsonEncode({
        'currentPrize': currentPrize,
        'winners': winners,
        'drawnNumbers': drawnNumbers,
      });
      await stateFile.writeAsString(json);
    } catch (e) {
      print('Failed to save state: $e');
    }
  }
  Future<void> loadState() async {
    try {
      if (await stateFile.exists()) {
        final content = await stateFile.readAsString();
        final obj = jsonDecode(content) as Map<String, dynamic>;
        final pr = obj['currentPrize'];
        if (pr is Map<String, dynamic>) {
          currentPrize = {
            'id': pr['id'],
            'title': pr['title'],
            'imageUrl': pr['imageUrl'],
          };
        }
        final dn = obj['drawnNumbers'];
        if (dn is List) {
          drawnNumbers
            ..clear()
            ..addAll(dn.map((e) => (e as num).toInt()));
        }
        final ws = obj['winners'];
        if (ws is List) {
          winners
            ..clear()
            ..addAll(ws.map((e) => e.toString()));
        }
      }
    } catch (e) {
      print('Failed to load state: $e');
    }
  }
  await loadState();

  Future<void> broadcast(Map<String, dynamic> message, {WebSocket? except}) async {
    final data = jsonEncode(message);
    for (final c in clients) {
      if (c.socket != except) {
        c.socket.add(data);
      }
    }
  }

  server.listen((HttpRequest req) async {
    if (req.uri.path == '/ws') {
      try {
        final socket = await WebSocketTransformer.upgrade(req);
        final client = Client(socket);
        clients.add(client);
        print('Client connected. Total: ${clients.length}');

        // Sync simple state to new client
        // Send full sync state
        final syncData = {
          'prize': currentPrize,
          'drawnNumbers': drawnNumbers,
        };
        socket.add(jsonEncode({'type': 'syncState', 'data': syncData}));
        if (winners.isNotEmpty) {
          socket.add(jsonEncode({'type': 'announceWinner', 'data': {'name': winners.last}}));
        }

        socket.listen((dynamic message) async {
          try {
            final obj = jsonDecode(message as String) as Map<String, dynamic>;
            final type = obj['type'] as String?;
            final data = obj['data'] as Map<String, dynamic>? ?? {};
            if (type == null) return;

            switch (type) {
              case 'setPrize':
                currentPrize = {
                  'id': data['id'],
                  'title': data['title'],
                  'imageUrl': data['imageUrl'],
                };
                await broadcast({'type': 'setPrize', 'data': currentPrize});
                await saveState();
                break;
              case 'drawNumber':
                final number = (data['number'] as num).toInt();
                drawnNumbers.add(number);
                await broadcast({'type': 'drawNumber', 'data': {'number': number}});
                await saveState();
                break;
              case 'resetGame':
                winners.clear();
                drawnNumbers.clear();
                await broadcast({'type': 'resetGame', 'data': {}});
                await saveState();
                break;
              case 'claimWin':
                final name = (data['name'] ?? 'desconhecido').toString();
                winners.add(name);
                await broadcast({'type': 'claimWin', 'data': {'name': name, 'timestamp': data['timestamp']}});
                break;
              case 'announceWinner':
                final name = (data['name'] ?? 'desconhecido').toString();
                winners.add(name);
                await broadcast({'type': 'announceWinner', 'data': {'name': name}});
                break;
              default:
                // echo unknown types for debugging
                await broadcast({'type': type, 'data': data});
            }
          } catch (e) {
            print('Error handling message: $e');
          }
        }, onDone: () {
          clients.remove(client);
          print('Client disconnected. Total: ${clients.length}');
        }, onError: (e) {
          clients.remove(client);
          print('Socket error: $e');
        });
      } catch (e) {
        print('Upgrade to WebSocket failed: $e');
        req.response
          ..statusCode = HttpStatus.internalServerError
          ..write('WebSocket upgrade failed')
          ..close();
      }
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  });
}