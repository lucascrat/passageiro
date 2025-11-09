import 'package:flutter/material.dart';
import '../models/bingo_models.dart';
import '../services/bingo_realtime_service.dart';
import '../services/bingo_service_factory.dart';

class BingoHistoryScreen extends StatefulWidget {
  const BingoHistoryScreen({super.key});

  @override
  State<BingoHistoryScreen> createState() => _BingoHistoryScreenState();
}

class _BingoHistoryScreenState extends State<BingoHistoryScreen> {
  late BingoRealtimeService _service;
  List<int> _drawnNumbers = [];
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
        });
        break;

      case BingoEventType.syncState:
        final drawnNumbers = (event.data['drawnNumbers'] as List?)
            ?.map((n) => n as int)
            .toList() ?? [];

        setState(() {
          _drawnNumbers = drawnNumbers;
        });
        break;

      case BingoEventType.resetGame:
        setState(() {
          _drawnNumbers.clear();
        });
        break;

      default:
        break;
    }
  }

  List<int> _getNumbersByColumn(String column) {
    int start, end;
    switch (column) {
      case 'B':
        start = 1; end = 15;
        break;
      case 'I':
        start = 16; end = 30;
        break;
      case 'N':
        start = 31; end = 45;
        break;
      case 'G':
        start = 46; end = 60;
        break;
      case 'O':
        start = 61; end = 75;
        break;
      default:
        return [];
    }
    
    return _drawnNumbers.where((n) => n >= start && n <= end).toList()..sort();
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
        title: const Text('Histórico de Números'),
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
            // Estatísticas
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      _drawnNumbers.length.toString(),
                      Colors.purple,
                    ),
                    _buildStatItem(
                      'Restantes',
                      (75 - _drawnNumbers.length).toString(),
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Progresso',
                      '${((_drawnNumbers.length / 75) * 100).toInt()}%',
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Números por coluna
            const Text(
              'Números por Coluna',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Colunas B-I-N-G-O
            Column(
              children: ['B', 'I', 'N', 'G', 'O'].map((column) {
                final numbers = _getNumbersByColumn(column);
                final totalInColumn = 15;
                final drawnInColumn = numbers.length;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getColumnColor(column),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  column,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getColumnName(column),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$drawnInColumn de $totalInColumn números',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getColumnColor(column).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${((drawnInColumn / totalInColumn) * 100).toInt()}%',
                                style: TextStyle(
                                  color: _getColumnColor(column),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (numbers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: numbers.map((number) {
                              return Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getColumnColor(column),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    number.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Todos os números em ordem
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ordem dos Sorteios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_drawnNumbers.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Nenhum número sorteado ainda',
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
                        children: _drawnNumbers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final number = entry.value;
                          final isLast = index == _drawnNumbers.length - 1;
                          
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getColumnColor(String column) {
    switch (column) {
      case 'B': return Colors.blue;
      case 'I': return Colors.indigo;
      case 'N': return Colors.purple;
      case 'G': return Colors.green;
      case 'O': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getColumnName(String column) {
    switch (column) {
      case 'B': return 'B (1-15)';
      case 'I': return 'I (16-30)';
      case 'N': return 'N (31-45)';
      case 'G': return 'G (46-60)';
      case 'O': return 'O (61-75)';
      default: return column;
    }
  }
}