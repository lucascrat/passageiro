import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/bingo_models.dart';
import '../services/bingo_realtime_service.dart';
import '../services/bingo_service_factory.dart';

class BingoGameScreen extends StatefulWidget {
  const BingoGameScreen({super.key});

  @override
  State<BingoGameScreen> createState() => _BingoGameScreenState();
}

class _BingoGameScreenState extends State<BingoGameScreen> {
  late BingoRealtimeService _service;
  Prize? _currentPrize;
  List<int> _drawnNumbers = [];
  int? _lastDrawnNumber;
  bool _connected = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _service = await createBingoService();
      await _service.connect();
      
      _service.events.listen(_onEvent);
      _service.connected.listen((connected) {
        if (mounted) {
          setState(() {
            _connected = connected;
            _loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _connected = false;
        });
      }
    }
  }

  void _onEvent(BingoEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case BingoEventType.drawNumber:
        final number = event.data['number'] as int;
        setState(() {
          _drawnNumbers.add(number);
          _lastDrawnNumber = number;
        });
        break;

      case BingoEventType.syncState:
        final prize = event.data['prize'] as Map<String, dynamic>?;
        final drawnNumbers = (event.data['drawnNumbers'] as List?)
            ?.map((n) => n as int)
            .toList() ?? [];

        setState(() {
          _drawnNumbers = drawnNumbers;
          _lastDrawnNumber = drawnNumbers.isNotEmpty ? drawnNumbers.last : null;
          
          if (prize != null) {
            _currentPrize = Prize(
              id: prize['id'],
              title: prize['title'],
              imageUrl: prize['imageUrl'],
            );
          }
        });
        break;

      case BingoEventType.setPrize:
        setState(() {
          _currentPrize = Prize(
            id: event.data['id'],
            title: event.data['title'],
            imageUrl: event.data['imageUrl'],
          );
        });
        break;

      case BingoEventType.resetGame:
        setState(() {
          _drawnNumbers.clear();
          _lastDrawnNumber = null;
          _currentPrize = null;
        });
        break;

      case BingoEventType.announceWinner:
        final winnerName = event.data['name'] ?? 'Desconhecido';
        Get.snackbar(
          'Temos um ganhador!',
          'Parabéns $winnerName!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bingo - Jogo Ativo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
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
                  _connected ? 'Online' : 'Offline',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prêmio Principal
            if (_currentPrize != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prêmio Principal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _currentPrize!.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _currentPrize!.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Último Número Sorteado
            Card(
              elevation: 4,
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Último Número Sorteado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _lastDrawnNumber?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Histórico de Números
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Números Sorteados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_drawnNumbers.length}/75',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_drawnNumbers.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aguardando o primeiro número...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _drawnNumbers.map((number) {
                          final isLast = number == _lastDrawnNumber;
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isLast ? Colors.orange : Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                              border: isLast
                                  ? Border.all(color: Colors.orange[700]!, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                number.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão para ir para a cartela
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed('/bingo-client');
                },
                icon: const Icon(Icons.grid_view),
                label: const Text('Ir para Minha Cartela'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
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
}