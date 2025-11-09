// Tela principal da Rifa da Sorte
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/rifa_controller.dart';
import '../models/rifa_models.dart';
import '../widgets/participacao_card_widget.dart';
import '../widgets/numero_animado_widget.dart';
import '../../../helper/route_helper.dart';

class RifaMainScreen extends StatefulWidget {
  const RifaMainScreen({super.key});

  @override
  State<RifaMainScreen> createState() => _RifaMainScreenState();
}

class _RifaMainScreenState extends State<RifaMainScreen>
    with TickerProviderStateMixin {
  final RifaController _rifaController = Get.find<RifaController>();
  
  // Anúncios
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  NativeAd? _nativeAd;
  BannerAd? _bannerAd;
  
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  bool _isNativeAdLoaded = false;
  bool _isBannerAdLoaded = false;
  bool _showNumbers = false;
  
  // Controle de seleção de números
  final Set<int> _selectedNumbers = <int>{};
  final RxList<int> _reservedNumbers = <int>[].obs;
  
  // YouTube Player
  YoutubePlayerController? _youtubeController;
  String? _youtubeUrl;
  
  late AnimationController _numberAnimationController;
  late AnimationController _buttonAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRewardedAd();
    _loadNativeAd();
    _loadBannerAd();
    _loadInterstitialAd();
    _fetchYoutubeUrl();
    
    // Carregar números reservados
    _loadReservedNumbers();
  }

  void _initializeAnimations() {
    _numberAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _loadRewardedAd() {
    setState(() {
      _isLoadingAd = true;
    });

    RewardedAd.load(
      adUnitId: _rifaController.getAdUnitId('rewarded'),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          setState(() {
            _isAdLoaded = true;
            _isLoadingAd = false;
          });
          _setupAdCallbacks();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
          setState(() {
            _isLoadingAd = false;
          });
          // Tentar carregar novamente após 30 segundos
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) _loadRewardedAd();
          });
        },
      ),
    );
  }

  void _setupAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        print('Ad showed fullscreen content.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('Ad dismissed fullscreen content.');
        ad.dispose();
        _rewardedAd = null;
        setState(() {
          _isAdLoaded = false;
        });
        // Carregar próximo anúncio
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('Ad failed to show fullscreen content: $error');
        ad.dispose();
        _rewardedAd = null;
        setState(() {
          _isAdLoaded = false;
        });
        _loadRewardedAd();
      },
    );
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: _rifaController.getAdUnitId('native'),
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isNativeAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Native ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _nativeAd?.load();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _rifaController.getAdUnitId('banner'),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _rifaController.getAdUnitId('interstitial'),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd(); // Carregar próximo anúncio
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _nativeAd?.dispose();
    _bannerAd?.dispose();
    _youtubeController?.dispose();
    _numberAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Rifa da Sorte',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showParticipacoes(),
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: GetX<RifaController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Banner no topo
                if (_isBannerAdLoaded && _bannerAd != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 50,
                    child: AdWidget(ad: _bannerAd!),
                  ),
                _buildHeader(),
                const SizedBox(height: 24),
                if (_youtubeController != null) _buildYoutubePlayer(),
                if (_youtubeController != null) const SizedBox(height: 24),
                // Anúncio nativo logo abaixo do vídeo do YouTube
                if (_isNativeAdLoaded && _nativeAd != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    height: 120,
                    child: AdWidget(ad: _nativeAd!),
                  ),
                _buildAdSection(),
                const SizedBox(height: 24),
                if (_showNumbers) _buildNumbersSection(),
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 24),
                // Teimozinha removida: botão ocultado
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B46C1),
            const Color(0xFF9333EA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.casino,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Assista o anúncio e ganhe\n3 números da sorte!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Valor do prêmio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Prêmio: R\$ ${_rifaController.rifaPremioValor.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Participações Hoje',
                '${_rifaController.participacoesHoje.value}/${_rifaController.maxParticipacoesDia}',
                Icons.today,
              ),
              _buildStatItem(
                'Total Participações',
                '${_rifaController.participacoes.length}',
                Icons.confirmation_number,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildAdSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Seção de seleção de números
            _buildNumberSelectionSection(),
            const SizedBox(height: 24),
            
            // Ícone do anúncio
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B46C1),
                    const Color(0xFF9333EA),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.play_circle_filled,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Anúncio Premiado',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Assista um anúncio completo e ganhe 3 números da sorte!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            
            // Status do anúncio
            if (_isLoadingAd)
              Column(
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF6B46C1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Carregando anúncio...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            else
              // Botão para assistir anúncio
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _canWatchAd() ? _showRewardedAd : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canWatchAd()
                        ? const Color(0xFF10B981)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _canWatchAd() ? 8 : 2,
                  ),
                  icon: _rifaController.isGeneratingNumbers.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 24),
                  label: Text(
                    _getButtonText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null && _canWatchAd()) {
      // Mostrar anúncio intersticial antes do premiado (opcional)
      _showInterstitialAd();
      
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          // Reservar números selecionados após assistir o anúncio completo
          _reservarNumerosSelecionados();
        },
      );
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    }
  }

  String _getButtonText() {
    if (_rifaController.isGeneratingNumbers.value) {
      return 'Reservando números...';
    }
    if (!_rifaController.podeParticipar.value) {
      return 'Limite diário atingido';
    }
    if (_selectedNumbers.length != 3) {
      return 'Selecione 3 números';
    }
    if (_isLoadingAd) {
      return 'Carregando anúncio...';
    }
    if (!_isAdLoaded) {
      return 'Anúncio indisponível';
    }
    return 'ASSISTIR ANÚNCIO';
  }

  Widget _buildNumbersSection() {
    if (_rifaController.numerosGerados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981),
            const Color(0xFF059669),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        child: Column(
          children: [
            const Text(
              'Seus Números da Sorte',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _rifaController.numerosGerados
                  .take(3)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final numero = entry.value;
                    
                    return NumeroAnimadoWidget(
                      numero: numero.numero,
                      animationController: _numberAnimationController,
                      backgroundColor: const Color(0xFF8B5CF6),
                      textColor: Colors.white,
                      size: 60,
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Boa sorte no próximo sorteio!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sorteios Ativos',
                  '${_rifaController.sorteiosAtivos.length}',
                  Icons.event,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Teimozinha Hoje',
                  '${_rifaController.tentativasTeimozinhaHoje.value}/${_rifaController.maxTentativasTeimozinhaDia}',
                  Icons.casino,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeimozinhaButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _rifaController.podeJogarTeimozinha.value
            ? _openTeimozinha
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
        icon: const Icon(Icons.casino, size: 24),
        label: Text(
          _rifaController.podeJogarTeimozinha.value
              ? 'JOGAR TEIMOZINHA'
              : 'Limite da Teimozinha atingido',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Verificar se pode assistir anúncio
  bool _canWatchAd() {
    return _isAdLoaded && 
           _rifaController.podeParticipar.value && 
           _selectedNumbers.length == 3;
  }

  // Carregar números já reservados
  Future<void> _loadReservedNumbers() async {
    try {
      final reserved = await _rifaController.getReservedNumbers();
      _reservedNumbers.value = reserved;
    } catch (e) {
      print('Erro ao carregar números reservados: $e');
    }
  }

  // Selecionar/deselecionar número
  void _toggleNumberSelection(int number) {
    if (_reservedNumbers.contains(number)) {
      return; // Número já reservado, não pode selecionar
    }

    setState(() {
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
      } else if (_selectedNumbers.length < 3) {
        _selectedNumbers.add(number);
      }
    });
  }

  // Reservar números selecionados
  Future<void> _reservarNumerosSelecionados() async {
    if (_selectedNumbers.length != 3) return;

    try {
      await _rifaController.reservarNumeros(_selectedNumbers.toList());
      
      setState(() {
        _showNumbers = true;
        _reservedNumbers.addAll(_selectedNumbers);
        _selectedNumbers.clear();
      });
      
      _numberAnimationController.forward();
      
      Get.snackbar(
        'Sucesso!',
        'Números reservados com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao reservar números: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Widget para seção de seleção de números
  Widget _buildNumberSelectionSection() {
    return Column(
      children: [
        const Text(
          'Escolha 3 números da sorte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione exatamente 3 números de 1 a 50',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        _buildNumberGrid(),
        const SizedBox(height: 16),
        if (_selectedNumbers.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6B46C1).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF6B46C1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selecionados: ${_selectedNumbers.join(', ')}',
                  style: const TextStyle(
                    color: Color(0xFF6B46C1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Widget para grid de números
  Widget _buildNumberGrid() {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 50,
        itemBuilder: (context, index) {
          final number = index + 1;
          final isSelected = _selectedNumbers.contains(number);
          final isReserved = _reservedNumbers.contains(number);
          
          return GestureDetector(
            onTap: () => _toggleNumberSelection(number),
            child: Container(
              decoration: BoxDecoration(
                color: isReserved
                    ? Colors.red.shade300
                    : isSelected
                        ? const Color(0xFF6B46C1)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6B46C1)
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isReserved || isSelected
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openTeimozinha() {
    Get.toNamed(RouteHelper.teimozinha);
  }

  void _showParticipacoes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Histórico de Participações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: GetX<RifaController>(
                    builder: (controller) {
                      if (controller.participacoes.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma participação ainda'),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.participacoes.length,
                        itemBuilder: (context, index) {
                          final participacao = controller.participacoes[index];
                          return ParticipacaoCardWidget(
                            participacao: participacao,
                            onTap: () => _showNumerosParticipacao(participacao),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNumerosParticipacao(RifaParticipacao participacao) async {
    final numeros = await _rifaController.getNumerosParticipacao(participacao.id);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Números Gerados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Participação de ${participacao.dataParticipacao.day}/${participacao.dataParticipacao.month}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: numeros
                  .take(3)
                  .map((numero) => Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: numero.sorteado ? Colors.green : Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${numero.numero}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Métodos do YouTube Player
  Future<void> _fetchYoutubeUrl() async {
    try {
      print('📺 Buscando URL do YouTube da rifa...');
      
      final response = await Supabase.instance.client
          .from('rifas')
          .select('youtube_live_url')
          .eq('ativo', true)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty && response.first['youtube_live_url'] != null) {
        final url = response.first['youtube_live_url'] as String;
        if (url.isNotEmpty) {
          _initializeYoutubePlayer(url);
        }
      } else {
        print('⚠️ Nenhuma URL do YouTube encontrada no banco, usando URL de exemplo');
        // URL de exemplo para teste
        _initializeYoutubePlayer('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      }
    } catch (e) {
      print('❌ Erro ao buscar URL do YouTube: $e');
      // URL de fallback
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
        print('✅ Player do YouTube inicializado: $videoId');
      } else {
        print('❌ URL do YouTube inválida: $url');
      }
    } catch (e) {
      print('❌ Erro ao inicializar player do YouTube: $e');
    }
  }

  Widget _buildYoutubePlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFF6B46C1),
          progressColors: const ProgressBarColors(
            playedColor: Color(0xFF6B46C1),
            handleColor: Color(0xFF9333EA),
          ),
          onReady: () {
            print('✅ YouTube Player está pronto');
          },
          onEnded: (metaData) {
            print('📺 Vídeo terminou');
          },
        ),
      ),
    );
  }
}