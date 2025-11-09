// Serviço para comunicação com APIs da Rifa Digital
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rifa_models.dart';

class RifaService {
  static const String baseUrl = 'https://your-project.supabase.co/functions/v1';
  final SupabaseClient _supabase = Supabase.instance.client;

  // Singleton pattern
  static final RifaService _instance = RifaService._internal();
  factory RifaService() => _instance;
  RifaService._internal();

  /// Obter vídeos premiados ativos
  Future<List<VideoPremiado>> getVideosPremiados() async {
    try {
      final response = await _supabase
          .from('videos_premiados')
          .select()
          .eq('ativo', true)
          .order('ordem');

      return (response as List)
          .map((json) => VideoPremiado.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar vídeos premiados: $e');
    }
  }

  /// Gerar números da rifa após assistir vídeo (método legado)
  Future<RifaParticipacao> gerarNumerosRifa({
    required String userId,
    required String videoId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'gerar-numeros-rifa',
        body: {
          'user_id': userId,
          'video_id': videoId,
        },
      );

      if (response.status != 200) {
        throw Exception('Erro na API: ${response.data}');
      }

      return RifaParticipacao.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao gerar números da rifa: $e');
    }
  }

  /// Gerar números da rifa após assistir anúncio AdMob
  Future<RifaParticipacao> gerarNumerosRifaAdMob({
    required String userId,
    required int quantidadeNumeros,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'gerar-numeros-rifa-admob',
        body: {
          'user_id': userId,
          'quantidade_numeros': quantidadeNumeros,
        },
      );

      if (response.status != 200) {
        throw Exception('Erro na API: ${response.data}');
      }

      return RifaParticipacao.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao gerar números da rifa AdMob: $e');
    }
  }

  /// Obter números já reservados
  Future<List<int>> getReservedNumbers() async {
    try {
      final response = await _supabase
          .from('rifa_numeros_reservados')
          .select('numero')
          .eq('ativo', true);

      return (response as List)
          .map((item) => item['numero'] as int)
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar números reservados: $e');
    }
  }

  /// Reservar números selecionados pelo usuário
  Future<RifaParticipacao> reservarNumerosRifa({
    required String userId,
    required List<int> numerosSelecionados,
  }) async {
    try {
      // Primeiro criar a participação
      final participacaoResponse = await _supabase
          .from('rifa_participacoes')
          .insert({
            'user_id': userId,
            'duracao_assistida': 30, // Duração padrão do anúncio
            'numeros_gerados': false,
            'tipo_participacao': 'manual',
            'numeros_selecionados': numerosSelecionados,
          })
          .select()
          .single();

      final participacao = RifaParticipacao.fromJson(participacaoResponse);

      // Usar a função do banco para reservar os números
      final reservaResponse = await _supabase.rpc(
        'reservar_numeros_rifa',
        params: {
          'p_numeros': numerosSelecionados,
          'p_participacao_id': participacao.id,
        },
      );

      if (reservaResponse['sucesso'] != true) {
        throw Exception(reservaResponse['mensagem'] ?? 'Erro ao reservar números');
      }

      return participacao;
    } catch (e) {
      throw Exception('Erro ao reservar números da rifa: $e');
    }
  }

  /// Obter participações do usuário
  Future<List<RifaParticipacao>> getParticipacoes(String userId) async {
    try {
      final response = await _supabase
          .from('rifa_participacoes')
          .select()
          .eq('user_id', userId)
          .order('data_participacao', ascending: false);

      return (response as List)
          .map((json) => RifaParticipacao.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar participações: $e');
    }
  }

  /// Obter números de uma participação
  Future<List<RifaNumero>> getNumerosParticipacao(String participacaoId) async {
    try {
      final response = await _supabase
          .from('rifa_numeros')
          .select()
          .eq('participacao_id', participacaoId)
          .order('numero');

      return (response as List)
          .map((json) => RifaNumero.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar números da participação: $e');
    }
  }

  /// Jogar na Teimozinha
  Future<TeimozinhaTentativa> jogarTeimozinha({
    required String userId,
    required int numeroEscolhido,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'jogar-teimozinha',
        body: {
          'user_id': userId,
          'numero_escolhido': numeroEscolhido,
        },
      );

      if (response.status != 200) {
        throw Exception('Erro na API: ${response.data}');
      }

      return TeimozinhaTentativa.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao jogar na Teimozinha: $e');
    }
  }

  /// Obter tentativas da Teimozinha do usuário
  Future<List<TeimozinhaTentativa>> getTentativasTeimozinha(String userId) async {
    try {
      final response = await _supabase
          .from('teimozinha_tentativas')
          .select()
          .eq('user_id', userId)
          .order('data_tentativa', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => TeimozinhaTentativa.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tentativas da Teimozinha: $e');
    }
  }

  /// Obter sorteios ativos
  Future<List<Sorteio>> getSorteiosAtivos() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('sorteios')
          .select()
          .eq('status', 'ativo')
          .lte('data_inicio', now)
          .gte('data_fim', now)
          .order('data_inicio');

      return (response as List)
          .map((json) => Sorteio.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar sorteios ativos: $e');
    }
  }

  /// Obter configurações do sistema
  Future<Map<String, String>> getConfiguracoes() async {
    try {
      final response = await _supabase
          .from('configuracoes_sistema')
          .select('chave, valor');

      final configs = <String, String>{};
      for (final item in response as List) {
        configs[item['chave']] = item['valor'];
      }

      return configs;
    } catch (e) {
      throw Exception('Erro ao buscar configurações: $e');
    }
  }

  /// Verificar se usuário pode participar da rifa hoje
  Future<bool> podeParticiparHoje(String userId) async {
    try {
      final hoje = DateTime.now();
      final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
      final fimHoje = inicioHoje.add(const Duration(days: 1));

      final response = await _supabase
          .from('rifa_participacoes')
          .select('id')
          .eq('user_id', userId)
          .gte('data_participacao', inicioHoje.toIso8601String())
          .lt('data_participacao', fimHoje.toIso8601String());

      final configs = await getConfiguracoes();
      final maxParticipacoesDia = int.parse(configs['max_participacoes_dia'] ?? '3');

      return (response as List).length < maxParticipacoesDia;
    } catch (e) {
      throw Exception('Erro ao verificar participações: $e');
    }
  }

  /// Verificar se usuário pode jogar Teimozinha hoje
  Future<bool> podeJogarTeimozinhaHoje(String userId) async {
    try {
      final hoje = DateTime.now();
      final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
      final fimHoje = inicioHoje.add(const Duration(days: 1));

      final response = await _supabase
          .from('teimozinha_tentativas')
          .select('id')
          .eq('user_id', userId)
          .gte('data_tentativa', inicioHoje.toIso8601String())
          .lt('data_tentativa', fimHoje.toIso8601String());

      final configs = await getConfiguracoes();
      final maxTentativasDia = int.parse(configs['max_tentativas_teimozinha_dia'] ?? '5');

      return (response as List).length < maxTentativasDia;
    } catch (e) {
      throw Exception('Erro ao verificar tentativas Teimozinha: $e');
    }
  }

  /// Stream para atualizações em tempo real dos sorteios
  Stream<List<Sorteio>> streamSorteios() {
    return _supabase
        .from('sorteios')
        .stream(primaryKey: ['id'])
        .eq('status', 'ativo')
        .map((data) => data.map((json) => Sorteio.fromJson(json)).toList());
  }

  /// Stream para atualizações das participações do usuário
  Stream<List<RifaParticipacao>> streamParticipacoes(String userId) {
    return _supabase
        .from('rifa_participacoes')
        .stream(primaryKey: ['id'])
        .map((data) => (data as List)
            .where((item) => item['user_id'] == userId)
            .map((json) => RifaParticipacao.fromJson(json))
            .toList());
  }
}