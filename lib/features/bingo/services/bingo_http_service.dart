import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/bingo_models.dart';
import 'bingo_realtime_service.dart';

class BingoHttpService implements BingoRealtimeService {
  final String baseUrl;
  final _controller = StreamController<BingoEvent>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();
  Timer? _pollTimer;
  String? _currentGameId;
  List<int> _lastDrawnNumbers = [];
  Prize? _lastPrize;

  @override
  Stream<BingoEvent> get events => _controller.stream;
  
  @override
  Stream<bool> get connected => _connectedController.stream;

  BingoHttpService(this.baseUrl);

  @override
  Future<void> connect() async {
    try {
      _connectedController.add(true);
      await _syncState();
      _startPolling();
    } catch (e) {
      _connectedController.add(false);
      rethrow;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollUpdates());
  }

  Future<void> _syncState() async {
    try {
      // Buscar jogo ativo
      final gameResponse = await http.get(
        Uri.parse('$baseUrl/api/android/games'),
        headers: {'Content-Type': 'application/json'},
      );

      if (gameResponse.statusCode == 200) {
        final payload = jsonDecode(gameResponse.body);
        final games = (payload is Map && payload['games'] is List)
            ? payload['games'] as List
            : <dynamic>[];
        final activeGame = games.firstWhere(
          (game) => game['status'] == 'active',
          orElse: () => null,
        );

        if (activeGame != null) {
          _currentGameId = activeGame['id'];
          
          // Buscar números sorteados (detalhe do jogo)
          final gameDetailResponse = await http.get(
            Uri.parse('$baseUrl/api/android/games/$_currentGameId'),
            headers: {'Content-Type': 'application/json'},
          );

          if (gameDetailResponse.statusCode == 200) {
            final detailPayload = jsonDecode(gameDetailResponse.body);
            final gameObj = (detailPayload is Map) ? detailPayload['game'] : null;
            final drawnNumbers = (gameObj != null && gameObj['drawn_numbers'] is List)
                ? (gameObj['drawn_numbers'] as List)
                    .map((n) => n['number'] as int)
                    .toList()
                : <int>[];
            _lastDrawnNumbers = drawnNumbers;
          }

          // Buscar prêmio
          final prizeResponse = await http.get(
            Uri.parse('$baseUrl/api/admin/games/$_currentGameId/prize'),
            headers: {'Content-Type': 'application/json'},
          );

          if (prizeResponse.statusCode == 200) {
            final prizeData = jsonDecode(prizeResponse.body);
            if (prizeData['prize'] != null) {
              final prize = prizeData['prize'];
              _lastPrize = Prize(
                id: prize['id'],
                title: prize['title'],
                imageUrl: prize['image_url'],
              );
            }
          }

          // Emitir evento de sincronização
          _controller.add(BingoEvent(BingoEventType.syncState, {
            'prize': _lastPrize == null ? null : {
              'id': _lastPrize!.id,
              'title': _lastPrize!.title,
              'imageUrl': _lastPrize!.imageUrl,
            },
            'drawnNumbers': _lastDrawnNumbers,
          }));
        }
      }
    } catch (e) {
      // print('Erro ao sincronizar estado: $e');
    }
  }

  Future<void> _pollUpdates() async {
    // Detectar troca de jogo ativo e sincronizar
    try {
      if (kDebugMode) {
        final gamesResp = await http.get(
          Uri.parse('$baseUrl/api/android/games'),
          headers: {'Content-Type': 'application/json'},
        );
        if (gamesResp.statusCode == 200) {
          final payload = jsonDecode(gamesResp.body);
          final games = (payload is Map && payload['games'] is List)
              ? payload['games'] as List
              : <dynamic>[];
          final activeGame = games.firstWhere(
            (game) => game['status'] == 'active',
            orElse: () => null,
          );
          final newActiveId = activeGame != null ? activeGame['id'] as String : null;
          if (newActiveId != null && newActiveId != _currentGameId) {
            _currentGameId = newActiveId;
            _lastDrawnNumbers = [];
            _lastPrize = null;
            await _syncState();
            return;
          }
        }
      }
    } catch (_) {
      // ignorar erros transitórios
    }

    if (_currentGameId == null) return;

    try {
      // Verificar novos números sorteados
      final numbersResponse = await http.get(
        Uri.parse('$baseUrl/api/admin/games/$_currentGameId/drawn-numbers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (numbersResponse.statusCode == 200) {
        final numbersData = jsonDecode(numbersResponse.body);
        final drawnNumbers = (numbersData['drawnNumbers'] as List)
            .map((n) => n['number'] as int)
            .toList();

        // Verificar se há novos números
        if (drawnNumbers.length > _lastDrawnNumbers.length) {
          final newNumbers = drawnNumbers.skip(_lastDrawnNumbers.length).toList();
          for (final number in newNumbers) {
            _controller.add(BingoEvent(BingoEventType.drawNumber, {'number': number}));
          }
          _lastDrawnNumbers = drawnNumbers;
        }
      }

      // Verificar mudanças no prêmio
      final prizeResponse = await http.get(
        Uri.parse('$baseUrl/api/admin/games/$_currentGameId/prize'),
        headers: {'Content-Type': 'application/json'},
      );

      if (prizeResponse.statusCode == 200) {
        final prizeData = jsonDecode(prizeResponse.body);
        if (prizeData['prize'] != null) {
          final prize = prizeData['prize'];
          final newPrize = Prize(
            id: prize['id'],
            title: prize['title'],
            imageUrl: prize['image_url'],
          );

          if (_lastPrize == null || 
              _lastPrize!.id != newPrize.id || 
              _lastPrize!.title != newPrize.title ||
              _lastPrize!.imageUrl != newPrize.imageUrl) {
            _lastPrize = newPrize;
            _controller.add(BingoEvent(BingoEventType.setPrize, {
              'id': newPrize.id,
              'title': newPrize.title,
              'imageUrl': newPrize.imageUrl,
            }));
          }
        }
      }
    } catch (e) {
      // print('Erro ao verificar atualizações: $e');
    }
  }

  @override
  void send(BingoEvent event) {
    // Para o cliente, apenas claimWin é relevante
    if (event.type == BingoEventType.claimWin && _currentGameId != null) {
      _sendClaimWin(event.data);
    }
  }

  Future<void> _sendClaimWin(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/admin/games/$_currentGameId/claim-win'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': data['name'] ?? 'Cliente',
          'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      // print('Erro ao enviar claim win: $e');
    }
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    await _controller.close();
    await _connectedController.close();
  }
}