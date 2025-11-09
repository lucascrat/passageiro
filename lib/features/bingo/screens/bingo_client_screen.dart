import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/bingo_models.dart';
import '../services/bingo_realtime_service.dart';
import '../services/bingo_service_factory.dart';
import '../services/participant_service.dart';
import '../services/admob_service.dart';
import '../data/bingo_database.dart';
import '../widgets/bingo_card_widget.dart';
import '../bingo_config.dart';
import 'participant_registration_screen.dart';

class BingoClientScreen extends StatefulWidget {
  const BingoClientScreen({super.key});
  @override
  State<BingoClientScreen> createState() => _BingoClientScreenState();
}

class _BingoClientScreenState extends State<BingoClientScreen> {
  late BingoCardManager _cardManager;
  Prize? _prize;
  BingoRealtimeService? _service;
  ParticipantService? _participantService;
  AdMobService? _adMobService;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  String _status = 'Inicializando...';
  bool _connected = false;
  bool _isInitializing = true;
  bool _isCheckingRegistration = true;
  final List<int> _drawnNumbers = [];
  
  // YouTube Player
  YoutubePlayerController? _youtubeController;
  String? _youtubeUrl;

  @override
  void initState() {
    super.initState();
    
    _cardManager = BingoCardManager();
    // Modificar para que a segunda cartela venha bloqueada por padrão
    if (_cardManager.cardCount == 1) {
      _cardManager.addCard(BingoCard.standard(isLocked: true)); // Segunda cartela bloqueada
    }
    
    // Resetar todas as cartelas para garantir que não há BINGO ativo por padrão
    // e garantir que todas as cartelas estejam em estado limpo
    for (int i = 0; i < _cardManager.cardCount; i++) {
      final wasLocked = _cardManager.cards[i].isLocked;
      _cardManager.generateNewCard(i);
      if (wasLocked) {
        _cardManager.cards[i].isLocked = true; // Manter o estado de bloqueio
      }
    }
    

    _adMobService = AdMobService();
    _adMobService!.initialize();
    _loadBannerAd();
    _fetchPrizeFromSupabase(); // Buscar prêmio do Supabase
    _fetchYoutubeUrl(); // Buscar URL do YouTube
    _checkParticipantRegistration();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6105194579101073/7147848618',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugLog('Banner ad failed to load: $err');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  Future<void> _checkParticipantRegistration() async {
    try {
      debugLog('👤 Verificando cadastro do participante...');
      setState(() {
        _status = 'Verificando cadastro...';
        _isCheckingRegistration = true;
      });

      // Inicializar serviço de participantes
      final supabase = Supabase.instance.client;
      _participantService = ParticipantService(supabase);

      // Verificar se o participante está registrado
      final isRegistered = await _participantService!.isParticipantRegistered();
      
      if (!isRegistered) {
        debugLog('❌ Participante não registrado. Redirecionando para cadastro...');
        if (mounted) {
          Get.off(() => const ParticipantRegistrationScreen());
        }
        return;
      }

      debugLog('✅ Participante registrado. Continuando...');
      await _loadCard();
      await _initializeService();
      
    } catch (e) {
      debugLog('❌ Erro ao verificar cadastro: $e');
      setState(() {
        _status = 'Erro ao verificar cadastro: $e';
        _isCheckingRegistration = false;
        _isInitializing = false;
      });
    }
  }

  Future<void> _loadCard() async {
    try {
      debugLog('🎯 Carregando cartelas salvas...');
      final data = await BingoDatabase.loadCard();
      if (data != null) {
        final cardsJson = jsonDecode(data['numbers']!);
        _cardManager = BingoCardManager.fromJson(cardsJson);
        debugLog('✅ Cartelas carregadas: ${_cardManager.cardCount} cartelas');
      } else {
        debugLog('📝 Nenhuma cartela salva encontrada. Usando cartela padrão.');
      }
    } catch (e) {
      debugLog('❌ Erro ao carregar cartelas: $e');
    }
  }

  Future<void> _initializeService() async {
    try {
      debugLog('🔌 Inicializando serviço de conexão...');
      setState(() {
        _status = 'Conectando...';
        _isCheckingRegistration = false;
      });

      _service = await createBingoService();
      
      // Configurar listeners
      _service!.events.listen(_handleEvent);
      _service!.connected.listen(_onConnectionChanged);
      
      // Conectar ao serviço
      await _service!.connect();
      
      setState(() {
        _isInitializing = false;
      });
      
      debugLog('✅ Serviço inicializado com sucesso');
      
    } catch (e) {
      debugLog('❌ Erro ao inicializar serviço: $e');
      setState(() {
        _status = 'Erro de conexão: $e';
        _isInitializing = false;
      });
    }
  }

  void _onConnectionChanged(bool connected) {
    setState(() {
      _connected = connected;
      _status = connected ? 'Conectado' : 'Desconectado';
    });
    debugLog('🔗 Status de conexão: ${connected ? 'Conectado' : 'Desconectado'}');
  }

  void _handleEvent(BingoEvent event) {
    debugLog('📨 Evento recebido: ${event.type}');
    switch (event.type) {
      case BingoEventType.drawNumber:
        _handleNumberDrawn(event.data);
        break;
      case BingoEventType.setPrize:
        _handlePrizeSet(event.data);
        break;
      case BingoEventType.announceWinner:
        _handleWinnerAnnounced(event.data);
        break;
      case BingoEventType.resetGame:
        _handleGameReset(event.data);
        break;
      case BingoEventType.syncState:
        _handleSyncState(event.data);
        break;
      default:
        debugLog('⚠️ Tipo de evento não reconhecido: ${event.type}');
    }
  }

  void _handleNumberDrawn(Map<String, dynamic> data) {
    final number = data['number'] as int;
    debugLog('🎱 Número sorteado: $number');
    
    setState(() {
      _drawnNumbers.add(number);
      // Manter apenas os últimos 20 números para performance
      if (_drawnNumbers.length > 20) {
        _drawnNumbers.removeAt(0);
      }
    });

    // Marcar número em todas as cartelas
    _cardManager.markNumberOnAllCards(number);
    _persistCards();

    // Verificar se alguma cartela tem BINGO
    final cardsWithBingo = _cardManager.getCardsWithBingo();
    if (cardsWithBingo.isNotEmpty) {
      _showBingoAlert(cardsWithBingo);
    }
  }

  void _handlePrizeSet(Map<String, dynamic> data) {
    debugLog('🏆 Prêmio definido: ${data['title']}');
    setState(() {
      _prize = Prize(
        id: data['id'],
        title: data['title'],
        imageUrl: data['imageUrl'],
      );
    });
  }

  void _handleWinnerAnnounced(Map<String, dynamic> data) {
    final winner = data['winner'];
    debugLog('🎉 Vencedor anunciado: $winner');
    
    Get.snackbar(
      '🎉 Temos um vencedor!',
      'Parabéns $winner!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _handleGameReset(Map<String, dynamic> data) {
    debugLog('🔄 Jogo reiniciado');
    setState(() {
      _drawnNumbers.clear();
      _prize = null;
      // Gerar novas cartelas para todas
      for (int i = 0; i < _cardManager.cardCount; i++) {
        _cardManager.generateNewCard(i);
      }
    });
    _persistCards();
    
    Get.snackbar(
      '🔄 Jogo Reiniciado',
      'Novas cartelas foram geradas!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleSyncState(Map<String, dynamic> data) {
    debugLog('🔄 Sincronizando estado inicial...');
    final drawnNumbers = List<int>.from(data['drawnNumbers'] ?? []);
    
    setState(() {
      _drawnNumbers.clear();
      _drawnNumbers.addAll(drawnNumbers);
      _connected = true;
    });

    // Marcar todos os números sorteados em todas as cartelas
    bool anyCardChanged = false;
    for (int number in drawnNumbers) {
      _cardManager.markNumberOnAllCards(number);
      anyCardChanged = true;
    }

    if (anyCardChanged) {
      _persistCards();
      debugLog('✅ Estado sincronizado: ${drawnNumbers.length} números marcados em todas as cartelas');
    }
  }

  void _showBingoAlert(List<BingoCard> cardsWithBingo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 BINGO!'),
        content: Text(
          cardsWithBingo.length == 1 
            ? 'Você fez BINGO na cartela ${_cardManager.cards.indexOf(cardsWithBingo.first) + 1}!'
            : 'Você fez BINGO em ${cardsWithBingo.length} cartelas!'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _claimBingo();
            },
            child: const Text('Reivindicar BINGO'),
          ),
        ],
      ),
    );
  }

  Future<void> _persistCards() async {
    try {
      final cardsJson = jsonEncode(_cardManager.toJson());
      await BingoDatabase.saveCard(cardsJson, '');
      debugLog('💾 Cartelas salvas com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao salvar cartelas: $e');
    }
  }

  void _claimBingo() {
    final cardsWithBingo = _cardManager.getCardsWithBingo();
    if (cardsWithBingo.isEmpty) {
      Get.snackbar(
        'Ops!',
        'Você não tem BINGO em nenhuma cartela.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _service?.sendEvent(BingoEvent(BingoEventType.claimWin, {
      'name': 'Cliente Mobile',
      'cardIds': cardsWithBingo.map((card) => card.id).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    }));

    Get.snackbar(
      '🎉 BINGO Reivindicado!',
      'Sua reivindicação foi enviada!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Rifa da Sorte removida: navegação desativada

  void _generateNewCard() {
    _cardManager.generateNewCard(0);
    _persistCards();
    
    Get.snackbar(
      'Nova Cartela',
      'Cartela 1 foi regenerada!',
      snackPosition: SnackPosition.BOTTOM,
    );
    setState(() {});
  }

  Future<void> _unlockNewCard() async {
    if (!_cardManager.canAddMore) {
      Get.snackbar(
        'Limite Atingido',
        'Você já possui o máximo de ${BingoCardManager.maxCards} cartelas.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!_adMobService!.isRewardedAdReady) {
      Get.snackbar(
        'Anúncio Indisponível',
        'Aguarde um momento e tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Mostrar dialog de confirmação
    final shouldWatch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎬 Assistir Vídeo'),
        content: const Text(
          'Assista a um vídeo premiado para desbloquear uma nova cartela e aumentar suas chances de ganhar!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Assistir'),
          ),
        ],
      ),
    );

    if (shouldWatch == true) {
      final rewarded = await _adMobService!.showRewardedAd();
      
      if (rewarded) {
        _cardManager.addCard();
        _persistCards();
        
        // Atualizar o índice da nova cartela
        final newIndex = _cardManager.cardCount - 1;
        
        Get.snackbar(
          '🎉 Nova Cartela Desbloqueada!',
          'Cartela ${_cardManager.cardCount} foi adicionada!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        setState(() {});
      } else {
        Get.snackbar(
          'Vídeo Não Concluído',
          'Você precisa assistir o vídeo completo para desbloquear a cartela.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    _adMobService?.dispose();
    _bannerAd?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _fetchPrizeFromSupabase() async {
    try {
      debugLog('🏆 Buscando prêmio atual do Supabase...');
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('bingo_games')
          .select('id, title, prize_image_url, prize_value')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      
      setState(() {
        _prize = Prize(
          id: response['id'].toString(),
          title: response['title'] ?? 'Prêmio Especial',
          imageUrl: response['prize_image_url'] ?? '',
          value: response['prize_value']?.toString() ?? '',
        );
      });
      debugLog('✅ Prêmio carregado: ${_prize!.title}');
        } catch (e) {
      debugLog('❌ Erro ao buscar prêmio: $e');
    }
  }

  Future<void> _fetchYoutubeUrl() async {
    try {
      debugLog('📺 Buscando URL do YouTube...');
      
      final response = await Supabase.instance.client
          .from('games')
          .select('youtube_live_url')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty && response.first['youtube_live_url'] != null) {
        final url = response.first['youtube_live_url'] as String;
        if (url.isNotEmpty) {
          _initializeYoutubePlayer(url);
        }
      } else {
        debugLog('⚠️ Nenhuma URL do YouTube encontrada no banco, usando URL de exemplo');
        // URL de exemplo para teste
        _initializeYoutubePlayer('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      }
    } catch (e) {
      debugLog('❌ Erro ao buscar URL do YouTube: $e');
      // Em caso de erro, usar URL de exemplo
      _initializeYoutubePlayer('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    }
  }

  void _initializeYoutubePlayer(String url) {
    try {
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        setState(() {
          _youtubeUrl = url;
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: true,
              loop: false,
              forceHD: false,
            ),
          );
        });
        debugLog('✅ Player do YouTube inicializado: $videoId');
      } else {
        debugLog('❌ URL do YouTube inválida: $url');
      }
    } catch (e) {
      debugLog('❌ Erro ao inicializar player do YouTube: $e');
    }
  }

  Future<void> _unlockCard(int cardIndex) async {
    if (cardIndex < 0 || cardIndex >= _cardManager.cardCount) return;
    
    // Se a cartela já está desbloqueada, não fazer nada
    if (!_cardManager.cards[cardIndex].isLocked) return;
    
    if (!_adMobService!.isRewardedAdReady) {
      Get.snackbar(
        'Anúncio Indisponível',
        'Aguarde um momento e tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Mostrar dialog de confirmação
    final shouldWatch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎬 Liberar com vídeo premiado'),
        content: Text(
          'Assista a um vídeo premiado para desbloquear a cartela ${cardIndex + 1} e aumentar suas chances de ganhar!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Assistir'),
          ),
        ],
      ),
    );

    if (shouldWatch == true) {
      final rewarded = await _adMobService!.showRewardedAd();
      
      if (rewarded) {
        // Desbloquear a cartela específica
        _cardManager.unlockCard(cardIndex);
        _persistCards();
        
        Get.snackbar(
          '🎉 Cartela ${cardIndex + 1} Desbloqueada!',
          'Agora você pode usar esta cartela!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        setState(() {});
      } else {
        Get.snackbar(
          'Vídeo Não Concluído',
          'Você precisa assistir o vídeo completo para desbloquear a cartela.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: (_isInitializing || _isCheckingRegistration)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isCheckingRegistration 
                        ? 'Verificando cadastro...' 
                        : 'Inicializando conexão...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Banner AdMob FIXO no topo (fora do scroll)
                    if (_isBannerAdReady && _bannerAd != null)
                      Container(
                        alignment: Alignment.center,
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    
                    // Conteúdo rolável abaixo do banner fixo
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                      
                      // Player do YouTube (logo abaixo do banner AdMob)
                      if (_youtubeController != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: Colors.purple,
                              progressColors: const ProgressBarColors(
                                playedColor: Colors.purple,
                                handleColor: Colors.purpleAccent,
                              ),
                              onReady: () {
                                debugLog('✅ Player do YouTube pronto');
                              },
                              onEnded: (metaData) {
                                debugLog('📺 Vídeo finalizado');
                              },
                            ),
                          ),
                        ),
                      
                      // Imagem do Prêmio
                      if (_prize != null && _prize!.imageUrl.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🏆 PRÊMIO',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _prize!.imageUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Imagem não disponível',
                                            style: TextStyle(color: Colors.grey, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _prize!.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_prize!.value.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Valor: ${_prize!.value}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      
                      // Status de Conexão e Números Sorteados
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Status de Conexão
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _connected ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _status,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _connected ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Números Sorteados
                            if (_drawnNumbers.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🎱 ÚLTIMOS NÚMEROS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 50,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _drawnNumbers.length > 15 ? 15 : _drawnNumbers.length,
                                      itemBuilder: (context, index) {
                                        final reversedIndex = _drawnNumbers.length - 1 - index;
                                        final number = _drawnNumbers[reversedIndex];
                                        final isLatest = number == _drawnNumbers.last;
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isLatest ? Colors.red : Colors.grey.shade300,
                                            shape: BoxShape.circle,
                                            border: isLatest ? Border.all(color: Colors.red.shade700, width: 2) : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              number.toString(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isLatest ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      

                      
                      // Título das cartelas
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.grid_view,
                              color: Colors.purple.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Suas Cartelas de Bingo',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_cardManager.cardCount} cartela${_cardManager.cardCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Lista vertical das cartelas
                      ...List.generate(_cardManager.cardCount, (index) {
                        final card = _cardManager.cards[index];
                        final isLocked = card.isLocked;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabeçalho da cartela
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLocked ? Colors.grey.shade200 : Colors.purple.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Cartela ${index + 1}',
                                        style: TextStyle(
                                          color: isLocked ? Colors.grey.shade600 : Colors.purple.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (isLocked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock,
                                              size: 14,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Bloqueada',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Cartela de Bingo
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  maxHeight: 400,
                                ),
                                child: Stack(
                                  children: [
                                    BingoCardWidget(card: card),
                                    if (isLocked)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.lock,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Cartela Bloqueada',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Assista um vídeo premiado\npara desbloquear',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              ElevatedButton.icon(
                                                onPressed: () => _unlockCard(index),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.purple,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                                ),
                                                icon: const Icon(Icons.play_arrow, size: 20),
                                                label: const Text(
                                                  'Liberar com vídeo premiado',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Botão GANHOU! - só aparece se a cartela tem bingo real e não está bloqueada
                              if (!isLocked && card.hasBingo() && _drawnNumbers.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton.icon(
                                    onPressed: _claimBingo,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.celebration,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    label: const Text(
                                      'GANHOU!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      
                            // Espaçamento final para evitar conflito com FloatingActionButtons
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      
      // Rifa da Sorte removida: botão flutuante desativado
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}