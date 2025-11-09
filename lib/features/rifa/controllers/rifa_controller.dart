// Controller para gerenciar estado da Rifa Digital
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/rifa_models.dart';
import '../services/rifa_service.dart';
import '../../dashboard/controllers/bottom_menu_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import 'package:uuid/uuid.dart';

class RifaController extends GetxController {
  final RifaService _rifaService = RifaService();

  // Estados observáveis
  final RxBool isLoading = false.obs;
  final RxBool isLoadingVideo = false.obs;
  final RxBool isGeneratingNumbers = false.obs;
  final RxBool isPlayingTeimozinha = false.obs;
  
  final RxList<VideoPremiado> videosPremiados = <VideoPremiado>[].obs;
  final RxList<RifaParticipacao> participacoes = <RifaParticipacao>[].obs;
  final RxList<RifaNumero> numerosGerados = <RifaNumero>[].obs;
  final RxList<TeimozinhaTentativa> tentativasTeimozinha = <TeimozinhaTentativa>[].obs;
  final RxList<Sorteio> sorteiosAtivos = <Sorteio>[].obs;
  
  final Rx<VideoPremiado?> videoAtual = Rx<VideoPremiado?>(null);
  final RxMap<String, String> configuracoes = <String, String>{}.obs;
  
  final RxBool podeParticipar = true.obs;
  final RxBool podeJogarTeimozinha = true.obs;
  final RxInt participacoesHoje = 0.obs;
  final RxInt tentativasTeimozinhaHoje = 0.obs;
  
  // Configurações AdMob - IDs de produção
  final RxString admobAppId = 'ca-app-pub-6105194579101073~4559648681'.obs;
  final RxString admobRewardedUnitId = 'ca-app-pub-6105194579101073/5241543417'.obs;
  final RxString admobNativeUnitId = 'ca-app-pub-6105194579101073/9352565859'.obs;
  final RxString admobInterstitialUnitId = 'ca-app-pub-6105194579101073/8690220873'.obs;
  final RxString admobBannerUnitId = 'ca-app-pub-6105194579101073~4559648681'.obs;
  final RxInt admobNumerosPorAnuncio = 3.obs;
  
  // IDs de teste para desenvolvimento
  final RxBool useTestAds = true.obs; // Manter em modo de teste por enquanto

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  /// Inicializar dados da rifa
  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      
      await Future.wait([
        loadVideosPremiados(),
        loadConfiguracoes(),
        loadSorteiosAtivos(),
      ]);

      // Carregar dados do usuário se estiver logado
      final userId = _getCurrentUserId();
      if (userId != null) {
        await Future.wait([
          loadParticipacoes(userId),
          loadTentativasTeimozinha(userId),
          checkParticipacaoPermissions(userId),
        ]);
      }
    } catch (e) {
      _showError('Erro ao carregar dados da rifa: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Carregar vídeos premiados
  Future<void> loadVideosPremiados() async {
    try {
      final videos = await _rifaService.getVideosPremiados();
      videosPremiados.value = videos;
      
      if (videos.isNotEmpty) {
        videoAtual.value = videos.first;
      }
    } catch (e) {
      _showError('Erro ao carregar vídeos: $e');
    }
  }

  /// Carregar configurações do sistema
  Future<void> loadConfiguracoes() async {
    try {
      final configs = await _rifaService.getConfiguracoes();
      configuracoes.value = configs;
      
      // Usar IDs fixos do AdMob (não dependem mais do banco de dados)
      // Os IDs já estão definidos nas variáveis observáveis
      admobNumerosPorAnuncio.value = int.parse(configs['admob_numeros_por_anuncio'] ?? '3');
    } catch (e) {
      _showError('Erro ao carregar configurações: $e');
    }
  }

  /// Obter ID do anúncio baseado no modo (teste ou produção)
  String getAdUnitId(String adType) {
    if (useTestAds.value) {
      // IDs de teste do Google AdMob
      switch (adType) {
        case 'rewarded':
          return 'ca-app-pub-3940256099942544/5224354917';
        case 'native':
          return 'ca-app-pub-3940256099942544/2247696110';
        case 'interstitial':
          return 'ca-app-pub-3940256099942544/1033173712';
        case 'banner':
          return 'ca-app-pub-3940256099942544/6300978111';
        default:
          return 'ca-app-pub-3940256099942544/5224354917';
      }
    } else {
      // IDs de produção
      switch (adType) {
        case 'rewarded':
          return admobRewardedUnitId.value;
        case 'native':
          return admobNativeUnitId.value;
        case 'interstitial':
          return admobInterstitialUnitId.value;
        case 'banner':
          return admobBannerUnitId.value;
        default:
          return admobRewardedUnitId.value;
      }
    }
  }

  /// Carregar sorteios ativos
  Future<void> loadSorteiosAtivos() async {
    try {
      final sorteios = await _rifaService.getSorteiosAtivos();
      sorteiosAtivos.value = sorteios;
    } catch (e) {
      _showError('Erro ao carregar sorteios: $e');
    }
  }

  /// Carregar participações do usuário
  Future<void> loadParticipacoes(String userId) async {
    try {
      final userParticipacoes = await _rifaService.getParticipacoes(userId);
      participacoes.value = userParticipacoes;
    } catch (e) {
      _showError('Erro ao carregar participações: $e');
    }
  }

  /// Carregar tentativas da Teimozinha
  Future<void> loadTentativasTeimozinha(String userId) async {
    try {
      final tentativas = await _rifaService.getTentativasTeimozinha(userId);
      tentativasTeimozinha.value = tentativas;
    } catch (e) {
      _showError('Erro ao carregar tentativas da Teimozinha: $e');
    }
  }

  /// Verificar permissões de participação
  Future<void> checkParticipacaoPermissions(String userId) async {
    try {
      final [canParticipate, canPlayTeimozinha] = await Future.wait([
        _rifaService.podeParticiparHoje(userId),
        _rifaService.podeJogarTeimozinhaHoje(userId),
      ]);

      podeParticipar.value = canParticipate;
      podeJogarTeimozinha.value = canPlayTeimozinha;

      // Contar participações e tentativas de hoje
      _countTodayActivities(userId);
    } catch (e) {
      _showError('Erro ao verificar permissões: $e');
    }
  }

  /// Contar atividades de hoje
  void _countTodayActivities(String userId) {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);

    // Contar participações de hoje
    participacoesHoje.value = participacoes
        .where((p) => p.dataParticipacao.isAfter(inicioHoje))
        .length;

    // Contar tentativas Teimozinha de hoje
    tentativasTeimozinhaHoje.value = tentativasTeimozinha
        .where((t) => t.dataTentativa.isAfter(inicioHoje))
        .length;
  }

  /// Gerar números da rifa após assistir anúncio AdMob
  Future<void> gerarNumerosRifa() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      _showError('Usuário não está logado');
      return;
    }

    if (!podeParticipar.value) {
      _showError('Você já atingiu o limite de participações hoje');
      return;
    }

    try {
      isGeneratingNumbers.value = true;

      final participacao = await _rifaService.gerarNumerosRifaAdMob(
        userId: userId,
        quantidadeNumeros: admobNumerosPorAnuncio.value,
      );

      // Atualizar listas
      participacoes.insert(0, participacao);
      
      // Carregar números gerados
      final numeros = await _rifaService.getNumerosParticipacao(participacao.id);
      numerosGerados.value = numeros;

      // Atualizar permissões
      await checkParticipacaoPermissions(userId);

      _showSuccess('Números gerados com sucesso!');
    } catch (e) {
      _showError('Erro ao gerar números: $e');
    } finally {
      isGeneratingNumbers.value = false;
    }
  }

  /// Obter números já reservados
  Future<List<int>> getReservedNumbers() async {
    try {
      return await _rifaService.getReservedNumbers();
    } catch (e) {
      _showError('Erro ao carregar números reservados: $e');
      return [];
    }
  }

  /// Reservar números selecionados pelo usuário
  Future<void> reservarNumeros(List<int> numerosSelecionados) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Usuário não está logado');
    }

    if (!podeParticipar.value) {
      throw Exception('Você já atingiu o limite de participações hoje');
    }

    if (numerosSelecionados.length != 3) {
      throw Exception('Deve selecionar exatamente 3 números');
    }

    try {
      isGeneratingNumbers.value = true;

      final participacao = await _rifaService.reservarNumerosRifa(
        userId: userId,
        numerosSelecionados: numerosSelecionados,
      );

      // Atualizar listas
      participacoes.insert(0, participacao);
      
      // Carregar números reservados
      final numeros = await _rifaService.getNumerosParticipacao(participacao.id);
      numerosGerados.value = numeros;

      // Atualizar permissões
      await checkParticipacaoPermissions(userId);

    } catch (e) {
      throw Exception('Erro ao reservar números: $e');
    } finally {
      isGeneratingNumbers.value = false;
    }
  }

  /// Jogar na Teimozinha
  Future<TeimozinhaTentativa?> jogarTeimozinha(int numeroEscolhido) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      _showError('Usuário não está logado');
      return null;
    }

    if (!podeJogarTeimozinha.value) {
      _showError('Você já atingiu o limite de tentativas hoje');
      return null;
    }

    try {
      isPlayingTeimozinha.value = true;

      final tentativa = await _rifaService.jogarTeimozinha(
        userId: userId,
        numeroEscolhido: numeroEscolhido,
      );

      // Atualizar lista de tentativas
      tentativasTeimozinha.insert(0, tentativa);

      // Atualizar permissões
      await checkParticipacaoPermissions(userId);

      // Mostrar resultado
      if (tentativa.ganhou) {
        _showSuccess('Parabéns! Você ganhou na Teimozinha!');
      } else {
        _showInfo('Que pena! Tente novamente.');
      }

      return tentativa;
    } catch (e) {
      _showError('Erro ao jogar na Teimozinha: $e');
      return null;
    } finally {
      isPlayingTeimozinha.value = false;
    }
  }

  /// Selecionar vídeo
  void selecionarVideo(VideoPremiado video) {
    videoAtual.value = video;
  }

  /// Obter números de uma participação específica
  Future<List<RifaNumero>> getNumerosParticipacao(String participacaoId) async {
    try {
      return await _rifaService.getNumerosParticipacao(participacaoId);
    } catch (e) {
      _showError('Erro ao carregar números: $e');
      return [];
    }
  }

  /// Refresh dos dados
  @override
  Future<void> refresh() async {
    await _initializeData();
  }

  /// Obter ID do usuário atual
  String? _getCurrentUserId() {
    try {
      // Tentar obter o ID do usuário autenticado
      final authController = Get.find<AuthController>();
      if (authController.isLoggedIn()) {
        // Tentar obter o ID do perfil do usuário
        final profileController = Get.find<ProfileController>();
        if (profileController.profileModel?.data?.id != null) {
          return profileController.profileModel!.data!.id.toString();
        }
        
        // Se não tiver ID do perfil, gerar um UUID baseado no token
        final token = authController.getUserToken();
        if (token.isNotEmpty) {
          // Gerar UUID determinístico baseado no token
          final uuid = Uuid();
          return uuid.v5(Uuid.NAMESPACE_URL, token);
        }
      }
      
      // Fallback: gerar UUID aleatório para usuário anônimo
      final uuid = Uuid();
      return uuid.v4();
    } catch (e) {
      // Em caso de erro, gerar UUID aleatório
      final uuid = Uuid();
      return uuid.v4();
    }
  }

  /// Obter limite de participações por dia
  int get maxParticipacoesDia {
    return int.parse(configuracoes['max_participacoes_dia'] ?? '3');
  }

  /// Obter limite de tentativas Teimozinha por dia
  int get maxTentativasTeimozinhaDia {
    return int.parse(configuracoes['max_tentativas_teimozinha_dia'] ?? '5');
  }

  /// Obter range de números da rifa
  int get rifaNumeroMin {
    return int.parse(configuracoes['rifa_numero_min'] ?? '1');
  }

  int get rifaNumeroMax {
    return int.parse(configuracoes['rifa_numero_max'] ?? '100');
  }

  /// Obter range de números da Teimozinha
  int get teimozinhaNumeroMin {
    return int.parse(configuracoes['teimozinha_numero_min'] ?? '1');
  }

  int get teimozinhaNumeroMax {
    return int.parse(configuracoes['teimozinha_numero_max'] ?? '10');
  }

  /// Obter valor do prêmio da rifa
  double get rifaPremioValor {
    return double.parse(configuracoes['rifa_premio_valor'] ?? '5000.00');
  }

  /// Métodos de feedback para o usuário
  void _showError(String message) {
    Get.snackbar(
      'Erro',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Sucesso',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showInfo(String message) {
    Get.snackbar(
      'Info',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}