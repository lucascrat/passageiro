// Tela da Teimozinha - Mini sorteio instantâneo
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../controllers/rifa_controller.dart';
import '../models/rifa_models.dart';
import '../widgets/numero_roleta_widget.dart';

class TeimozinhaScreen extends StatefulWidget {
  const TeimozinhaScreen({super.key});

  @override
  State<TeimozinhaScreen> createState() => _TeimozinhaScreenState();
}

class _TeimozinhaScreenState extends State<TeimozinhaScreen>
    with TickerProviderStateMixin {
  final RifaController _rifaController = Get.find<RifaController>();
  
  late AnimationController _roletaController;
  late AnimationController _resultController;
  late AnimationController _confettiController;
  
  int? _numeroEscolhido;
  int? _numeroSorteado;
  bool _isPlaying = false;
  bool _showResult = false;
  TeimozinhaTentativa? _ultimaTentativa;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _roletaController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _roletaController.dispose();
    _resultController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Teimozinha',
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
            onPressed: _showHistorico,
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: GetX<RifaController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildNumberSelector(),
                const SizedBox(height: 32),
                _buildRoletaSection(),
                const SizedBox(height: 32),
                if (_showResult) _buildResultSection(),
                const SizedBox(height: 32),
                _buildPlayButton(),
                const SizedBox(height: 24),
                _buildStatsSection(),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444),
            const Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
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
            'Teimozinha',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha um número de ${_rifaController.teimozinhaNumeroMin} a ${_rifaController.teimozinhaNumeroMax}\ne teste sua sorte!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Tentativas Hoje',
                '${_rifaController.tentativasTeimozinhaHoje.value}/${_rifaController.maxTentativasTeimozinhaDia}',
                Icons.today,
              ),
              _buildStatItem(
                'Total Tentativas',
                '${_rifaController.tentativasTeimozinha.length}',
                Icons.casino,
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
            fontSize: 16,
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

  Widget _buildNumberSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha seu número da sorte:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              _rifaController.teimozinhaNumeroMax - _rifaController.teimozinhaNumeroMin + 1,
              (index) {
                final numero = _rifaController.teimozinhaNumeroMin + index;
                final isSelected = _numeroEscolhido == numero;
                
                return GestureDetector(
                  onTap: _isPlaying ? null : () => _selectNumber(numero),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEF4444) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFDC2626) : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        '$numero',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoletaSection() {
    return Container(
      height: 200,
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
      child: Center(
        child: _isPlaying
            ? NumeroRoletaWidget(
                animationController: _roletaController,
                numeroFinal: _numeroSorteado,
                numeroMin: _rifaController.teimozinhaNumeroMin,
                numeroMax: _rifaController.teimozinhaNumeroMax,
              )
            : Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.red.shade400,
                      Colors.red.shade600,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.casino,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_ultimaTentativa == null) return const SizedBox.shrink();

    final ganhou = _ultimaTentativa!.ganhou;
    
    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_resultController.value * 0.2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ganhou
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFF6B7280), const Color(0xFF4B5563)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (ganhou ? Colors.green : Colors.grey).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  ganhou ? Icons.celebration : Icons.sentiment_dissatisfied,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  ganhou ? 'PARABÉNS!' : 'QUE PENA!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ganhou
                      ? 'Você acertou o número!'
                      : 'Não foi dessa vez, tente novamente!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResultNumber(
                      'Seu número',
                      _ultimaTentativa!.numeroEscolhido,
                      Colors.white.withOpacity(0.9),
                    ),
                    _buildResultNumber(
                      'Número sorteado',
                      _ultimaTentativa!.numeroSorteado,
                      ganhou ? Colors.yellow : Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
                if (ganhou && _ultimaTentativa!.premioDescricao != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Prêmio: ${_ultimaTentativa!.premioDescricao}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultNumber(String label, int numero, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GetX<RifaController>(
      builder: (controller) {
        final canPlay = controller.podeJogarTeimozinha.value && 
                       _numeroEscolhido != null && 
                       !_isPlaying;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: canPlay ? _jogar : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canPlay ? const Color(0xFFEF4444) : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: canPlay ? 8 : 2,
            ),
            icon: _isPlaying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.casino, size: 24),
            label: Text(
              _getPlayButtonText(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getPlayButtonText() {
    if (_isPlaying) return 'Sorteando...';
    if (!_rifaController.podeJogarTeimozinha.value) {
      return 'Limite diário atingido';
    }
    if (_numeroEscolhido == null) return 'Escolha um número';
    return 'JOGAR TEIMOZINHA';
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
            'Suas Estatísticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GetX<RifaController>(
            builder: (controller) {
              final tentativas = controller.tentativasTeimozinha;
              final vitorias = tentativas.where((t) => t.ganhou).length;
              final taxaVitoria = tentativas.isNotEmpty 
                  ? (vitorias / tentativas.length * 100).toStringAsFixed(1)
                  : '0.0';

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Vitórias',
                      '$vitorias',
                      Icons.emoji_events,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Taxa de Vitória',
                      '$taxaVitoria%',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
              ],
            );
          }),
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
              fontSize: 18,
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

  void _selectNumber(int numero) {
    setState(() {
      _numeroEscolhido = numero;
      _showResult = false;
    });
  }

  void _jogar() async {
    if (_numeroEscolhido == null) return;

    setState(() {
      _isPlaying = true;
      _showResult = false;
    });

    // Gerar número sorteado localmente para animação
    final random = Random();
    _numeroSorteado = _rifaController.teimozinhaNumeroMin + 
        random.nextInt(_rifaController.teimozinhaNumeroMax - _rifaController.teimozinhaNumeroMin + 1);

    // Iniciar animação da roleta
    _roletaController.forward();

    // Aguardar animação da roleta
    await Future.delayed(const Duration(seconds: 3));

    // Fazer chamada para API
    try {
      final tentativa = await _rifaController.jogarTeimozinha(_numeroEscolhido!);
      
      setState(() {
        _ultimaTentativa = tentativa;
        _numeroSorteado = tentativa?.numeroSorteado;
        _showResult = true;
        _isPlaying = false;
      });

      // Animar resultado
      _resultController.forward();

      // Se ganhou, animar confetti
      if (tentativa?.ganhou == true) {
        _confettiController.forward();
      }

    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
    }

    // Reset para próxima jogada
    _roletaController.reset();
    _resultController.reset();
    _confettiController.reset();
  }

  void _showHistorico() {
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
                    'Histórico da Teimozinha',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: GetX<RifaController>(
                    builder: (controller) {
                      if (controller.tentativasTeimozinha.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma tentativa ainda'),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.tentativasTeimozinha.length,
                        itemBuilder: (context, index) {
                          final tentativa = controller.tentativasTeimozinha[index];
                          return _buildHistoricoItem(tentativa);
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

  Widget _buildHistoricoItem(TeimozinhaTentativa tentativa) {
    final ganhou = tentativa.ganhou;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ganhou ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ganhou ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ganhou ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ganhou ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ganhou ? 'Vitória!' : 'Tentativa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ganhou ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seu número: ${tentativa.numeroEscolhido} | Sorteado: ${tentativa.numeroSorteado}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '${tentativa.dataTentativa.day}/${tentativa.dataTentativa.month} às ${tentativa.dataTentativa.hour}:${tentativa.dataTentativa.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (ganhou && tentativa.premioDescricao != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tentativa.premioDescricao!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}