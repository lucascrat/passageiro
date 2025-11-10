import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bingo_models.dart';
import '../bingo_config.dart';
import 'bingo_realtime_service.dart';

class BingoSupabaseService implements BingoRealtimeService {
  final SupabaseClient _client;
  final _eventController = StreamController<BingoEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  @override
  Stream<BingoEvent> get events => _eventController.stream;
  
  @override
  Stream<bool> get connected => _connectionController.stream;

  late RealtimeChannel _channel;
  String? _currentGameId;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isDisposed = false;

  BingoSupabaseService._(this._client);

  /// Cria uma nova instância do serviço Supabase
  static Future<BingoSupabaseService> create() async {
    debugLog('Iniciando criação do BingoSupabaseService...');
    
    try {
      // Inicializar Supabase se necessário
      SupabaseClient client;
      try {
        client = Supabase.instance.client;
        debugLog('Supabase já estava inicializado');
      } catch (e) {
        debugLog('Inicializando Supabase pela primeira vez...');
        await Supabase.initialize(
          url: kSupabaseUrl,
          anonKey: kSupabaseAnonKey,
        );
        client = Supabase.instance.client;
        debugLog('Supabase inicializado com sucesso');
      }

      // Testar conectividade básica
      await _testConnectivity(client);
      
      final service = BingoSupabaseService._(client);
      await service._initialize();
      
      debugLog('BingoSupabaseService criado com sucesso');
      return service;
    } catch (e) {
      debugLog('Erro ao criar BingoSupabaseService: $e');
      rethrow;
    }
  }

  /// Testa a conectividade com o Supabase
  static Future<void> _testConnectivity(SupabaseClient client) async {
    try {
      debugLog('Testando conectividade de rede...');
      
      // Verificar conectividade de rede
      final result = await InternetAddress.lookup('yubztvbrgrldfueelxfh.supabase.co');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception('Sem conectividade de rede');
      }
      debugLog('Conectividade de rede OK');

      // Testar acesso ao Supabase
      final response = await client.from('games').select('count').limit(1);
      debugLog('Conectividade Supabase OK: ${response.length} registros');
    } catch (e) {
      debugLog('Falha na conectividade: $e');
      throw Exception('Não foi possível conectar ao Supabase: $e');
    }
  }

  /// Inicializa o serviço
  Future<void> _initialize() async {
    try {
      debugLog('Inicializando serviço...');
      
      // Obter ou criar um jogo ativo
      _currentGameId = await _ensureActiveGame();
      debugLog('Game ID: $_currentGameId');
      
      // Conectar automaticamente
      await connect();
    } catch (e) {
      debugLog('Erro na inicialização: $e');
      rethrow;
    }
  }

  /// Garante que existe um jogo ativo
  Future<String> _ensureActiveGame() async {
    try {
      debugLog('Buscando jogo ativo...');
      
      // Buscar jogo ativo existente - ordenar por mais recente primeiro
      final activeGames = await _client
          .from('games')
          .select('id, created_at, started_at, name')
          .eq('status', 'active')
          .order('started_at', ascending: false)
          .order('created_at', ascending: false);
      
      if (activeGames.isNotEmpty) {
        // Pegar o jogo mais recente que foi iniciado
        final gameId = activeGames.first['id'] as String;
        final gameName = activeGames.first['name'] as String?;
        debugLog('Jogo ativo encontrado: $gameId (Nome: $gameName)');
        debugLog('Total de jogos ativos: ${activeGames.length}');
        return gameId;
      }
      
      // Criar novo jogo se não existir
      debugLog('Criando novo jogo...');
      final newGame = await _client
          .from('games')
          .insert({'status': 'active'})
          .select('id')
          .single();
      
      final gameId = newGame['id'] as String;
      debugLog('Novo jogo criado: $gameId');
      return gameId;
    } catch (e) {
      debugLog('Erro ao obter/criar jogo: $e');
      rethrow;
    }
  }

  @override
  Future<void> connect() async {
    if (_isDisposed) return;
    
    try {
      debugLog('Conectando ao Supabase Realtime...');
      
      // Cancelar timer de reconexão se existir
      _reconnectTimer?.cancel();
      
      // Desconectar canal anterior se existir
      try {
        await _channel.unsubscribe();
        debugLog('Canal anterior desconectado');
      } catch (e) {
        debugLog('Nenhum canal anterior para desconectar');
      }

      // Criar novo canal
      final channelName = '${kRealtimeChannelName}_$_currentGameId';
      debugLog('Criando canal: $channelName');
      
      _channel = _client.channel(channelName, opts: RealtimeChannelConfig(ack: true));
      
      // Configurar listeners para números sorteados
      _channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'drawn_numbers',
        callback: _onNumberDrawn,
      );
      
      // Configurar listeners para vencedores
      _channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'winners',
        callback: _onWinnerAnnounced,
      );
      
      // Configurar listeners para prêmios
      _channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'prizes',
        callback: _onPrizeUpdated,
      );

      // Subscrever ao canal
      _channel.subscribe((status, [error]) {
        debugLog('Status do canal: $status (tipo: ${status.runtimeType})');
        
        if (_isDisposed) return;
        
        // Verificar se é subscribed (conectado)
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugLog('✅ Conectado ao Supabase Realtime');
          _isConnected = true;
          _connectionController.add(true);
          
          // Sincronizar estado inicial APÓS conectar
          _syncInitialState();
        } else if (status == RealtimeSubscribeStatus.closed) {
          debugLog('🔌 Conexão fechada');
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        } else if (status == RealtimeSubscribeStatus.channelError) {
          debugLog('❌ Erro no canal: $error');
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        } else if (status == RealtimeSubscribeStatus.timedOut) {
          debugLog('⏰ Timeout na conexão');
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        } else {
          debugLog('Status desconhecido: $status');
          _isConnected = false;
          _connectionController.add(false);
        }
      });
      
    } catch (e) {
      debugLog('Erro ao conectar: $e');
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  /// Sincroniza o estado inicial do jogo
  Future<void> _syncInitialState() async {
    try {
      debugLog('🔄 Sincronizando estado inicial...');
      
      if (_currentGameId == null) {
        debugLog('❌ Game ID é null, não é possível sincronizar');
        return;
      }
      
      debugLog('🎯 Buscando números sorteados para game: $_currentGameId');
      
      // Buscar números já sorteados
      final drawnNumbersData = await _client
          .from('drawn_numbers')
          .select('number, drawn_at, is_manual')
          .eq('game_id', _currentGameId!)
          .order('drawn_at');
      
      debugLog('📊 Encontrados ${drawnNumbersData.length} números no banco de dados');
      
      // Extrair apenas os números para o evento syncState
      final drawnNumbers = drawnNumbersData
          .map((record) => (record['number'] as num).toInt())
          .toList();
      
      debugLog('📥 Números para sincronização: $drawnNumbers');
      
      // Enviar evento syncState com todos os números de uma vez, incluindo gameId
      _eventController.add(BingoEvent(BingoEventType.syncState, {
        'gameId': _currentGameId,
        'drawnNumbers': drawnNumbers,
      }));
      
      debugLog('✅ Estado inicial sincronizado: ${drawnNumbers.length} números enviados via syncState');
      
      // Buscar prêmio atual se existir
      final prizes = await _client
          .from('prizes')
          .select('id, title, image_url')
          .eq('game_id', _currentGameId!)
          .limit(1);
      
      if (prizes.isNotEmpty) {
        final prize = prizes.first;
        debugLog('🎁 Prêmio encontrado: ${prize['title']}');
        _eventController.add(BingoEvent(BingoEventType.setPrize, {
          'id': prize['id'],
          'title': prize['title'],
          'imageUrl': prize['image_url'],
        }));
      } else {
        debugLog('🎁 Nenhum prêmio encontrado para este jogo');
      }
      
    } catch (e) {
      debugLog('❌ Erro ao sincronizar estado inicial: $e');
    }
  }

  /// Callback para números sorteados
  void _onNumberDrawn(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      final gameId = record['game_id'] as String;
      
      if (gameId != _currentGameId) {
        debugLog('Número de jogo diferente ignorado: $gameId != $_currentGameId');
        return;
      }
      
      final number = (record['number'] as num).toInt();
      debugLog('📥 Número sorteado recebido: $number');
      
      _eventController.add(BingoEvent(BingoEventType.drawNumber, {'number': number}));
    } catch (e) {
      debugLog('Erro ao processar número sorteado: $e');
    }
  }

  /// Callback para vencedores anunciados
  void _onWinnerAnnounced(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      final gameId = record['game_id'] as String;
      
      if (gameId != _currentGameId) {
        debugLog('Vencedor de jogo diferente ignorado: $gameId != $_currentGameId');
        return;
      }
      
      final name = record['name'] as String? ?? 'Desconhecido';
      debugLog('🏆 Vencedor anunciado: $name');
      
      _eventController.add(BingoEvent(BingoEventType.announceWinner, {'name': name}));
    } catch (e) {
      debugLog('Erro ao processar vencedor: $e');
    }
  }

  /// Callback para prêmios atualizados
  void _onPrizeUpdated(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      final gameId = record['game_id'] as String;
      
      if (gameId != _currentGameId) {
        debugLog('Prêmio de jogo diferente ignorado: $gameId != $_currentGameId');
        return;
      }
      
      debugLog('🎁 Prêmio atualizado: ${record['title']}');
      
      _eventController.add(BingoEvent(BingoEventType.setPrize, {
        'id': record['id'],
        'title': record['title'],
        'imageUrl': record['image_url'],
      }));
    } catch (e) {
      debugLog('Erro ao processar prêmio: $e');
    }
  }

  /// Agenda uma tentativa de reconexão
  void _scheduleReconnect() {
    if (_isDisposed) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(kReconnectDelay, () {
      if (!_isDisposed && !_isConnected) {
        debugLog('🔄 Tentando reconectar...');
        connect().catchError((e) {
          debugLog('❌ Falha na reconexão: $e');
        });
      }
    });
  }

  @override
  Future<void> sendEvent(BingoEvent event) async {
    try {
      if (_currentGameId == null) {
        debugLog('Não é possível enviar evento: game_id é null');
        return;
      }

      switch (event.type) {
        case BingoEventType.claimWin:
          debugLog('Enviando claim de vitória para bingo_claims...');
          final participantId = event.data['participant_id'] as String?;
          // Aceita tanto 'claim_type' quanto 'bingo_type' vindo do payload
          final claimType = (event.data['claim_type'] as String?) ?? (event.data['bingo_type'] as String?);

          if (participantId == null || participantId.isEmpty || claimType == null || claimType.isEmpty) {
            debugLog('Payload inválido para claimWin: participant_id ou claim_type ausente');
            return;
          }
          // 1) Tenta via API admin (usa service role e evita bloqueios de RLS)
          try {
            final uri = Uri.parse('$kBingoAdminUrl/api/admin/claims');
            final resp = await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'game_id': _currentGameId,
                'participant_id': participantId,
                'claim_type': claimType,
              }),
            );
            if (resp.statusCode >= 200 && resp.statusCode < 300) {
              debugLog('✅ Claim enviado via API admin com sucesso (status ${resp.statusCode})');
              break;
            } else {
              debugLog('API admin falhou (${resp.statusCode}): ${resp.body}. Tentando inserir direto no Supabase...');
            }
          } catch (e) {
            debugLog('Falha ao enviar via API admin: $e. Tentando insert direto...');
          }

          // 2) Fallback: tenta inserir direto (pode falhar por RLS se não autenticado)
          await _client.from('bingo_claims').insert({
            'game_id': _currentGameId,
            'participant_id': participantId,
            'bingo_type': claimType,
            'validated': false,
          });
          break;
        default:
          debugLog('Tipo de evento não suportado para envio: ${event.type}');
      }
    } catch (e) {
      debugLog('Erro ao enviar evento: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    debugLog('Desconectando...');
    _isDisposed = true;
    _reconnectTimer?.cancel();
    
    try {
      await _channel.unsubscribe();
    } catch (e) {
      debugLog('Erro ao desinscrever do canal: $e');
    }
    
    _isConnected = false;
    _connectionController.add(false);
  }

  @override
  Future<void> close() async {
    debugLog('Fechando serviço...');
    await disconnect();
    
    await _eventController.close();
    await _connectionController.close();
  }
}