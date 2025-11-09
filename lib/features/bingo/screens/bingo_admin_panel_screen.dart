import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/bingo_models.dart';
import '../services/bingo_realtime_service.dart';
import '../services/bingo_service_factory.dart';

class BingoAdminPanelScreen extends StatefulWidget {
  const BingoAdminPanelScreen({super.key});

  @override
  State<BingoAdminPanelScreen> createState() => _BingoAdminPanelScreenState();
}

class _BingoAdminPanelScreenState extends State<BingoAdminPanelScreen> {
  BingoRealtimeService? _ws;
  final _numberController = TextEditingController();
  final _prizeTitle = TextEditingController();
  final _prizeImage = TextEditingController();
  final List<String> _winners = [];
  final List<int> _drawnNumbers = [];
  bool _connected = false;

  // UI enhancements
  Color _accentColor = Colors.indigo;
  final List<Color> _palette = const [
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.purple,
    Colors.blueGrey,
    Colors.green,
  ];
  String? _imagePreviewUrl;

  @override
  void initState() {
    super.initState();
    
    // Configurar listener para preview da imagem
    _prizeImage.addListener(() {
      final v = _prizeImage.text.trim();
      setState(() => _imagePreviewUrl = v.isEmpty ? null : v);
    });
    
    // Inicializar serviço do bingo
    _initializeBingoService();
  }
  
  Future<void> _initializeBingoService() async {
    // print('🔄 Iniciando serviço do bingo...');
    
    // Timeout para toda a inicialização
    const initTimeout = Duration(seconds: 15);
    
    try {
      await _performInitialization().timeout(initTimeout);
      // print('✅ Serviço do bingo inicializado com sucesso');
    } on TimeoutException {
      // print('⏰ Timeout na inicialização do serviço: $e');
      _handleInitializationFailure('Timeout na conexão (15s). Verifique sua internet.');
    } catch (e) {
      // print('❌ Erro ao inicializar serviço do bingo: $e');
      // print('📍 Stack trace: $stackTrace');
      _handleInitializationFailure('Erro na inicialização: ${e.toString()}');
    }
  }

  Future<void> _performInitialization() async {
    // print('🔧 Criando serviço do bingo...');
    // print('🌐 URL de conexão: $kBingoWsUrl');
    // print('🔧 Usando Supabase: $kUseSupabase');
    
    _ws = await createBingoService();
    // print('✅ Serviço criado com sucesso: ${_ws.runtimeType}');
    
    // print('🔌 Conectando ao serviço...');
    await _ws!.connect();
    // print('✅ Conectado ao serviço');
    
    // Configurar listener para conexão
    _ws!.connected.listen((c) {
      // print('📡 Status de conexão alterado: $c');
      if (!mounted) return;
      setState(() => _connected = c);
    });
    
    // Configurar listener para eventos
    _ws!.events.listen((e) {
      // print('📨 Evento recebido: ${e.type} - ${e.data}');
      if (!mounted) return;
      _handleBingoEvent(e);
    });
  }

  void _handleInitializationFailure(dynamic error) {
    // print('❌ Falha na inicialização: $error');
    // print('🔍 Tipo do erro: ${error.runtimeType}');
    // print('📍 Stack trace: ${StackTrace.current}');
    
    if (!mounted) return;
    
    // Forçar criação do serviço e mostrar tela de conexão
    setState(() {
      _ws = null;
      _connected = false;
    });
  }

  void _retryInitialization() {
    // print('🔄 Tentando reconectar...');
    _initializeBingoService();
  }
  
  void _handleBingoEvent(BingoEvent e) {
    switch (e.type) {
      case BingoEventType.claimWin:
        setState(() => _winners.add(e.data['name'] ?? 'desconhecido'));
        break;
      case BingoEventType.drawNumber:
        final n = e.data['number'] as int;
        setState(() => _drawnNumbers.add(n));
        break;
      case BingoEventType.resetGame:
        setState(() {
          _winners.clear();
          _drawnNumbers.clear();
        });
        break;
      case BingoEventType.syncState:
        final drawn = (e.data['drawnNumbers'] as List?)?.map((v) => v as int).toList() ?? <int>[];
        setState(() {
          _drawnNumbers
            ..clear()
            ..addAll(drawn);
        });
        break;
      case BingoEventType.setPrize:
        // no-op for admin UI beyond toast, can add preview
        break;
      case BingoEventType.announceWinner:
        setState(() => _winners.add(e.data['name'] ?? 'desconhecido'));
        break;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _prizeTitle.dispose();
    _prizeImage.dispose();
    super.dispose();
  }

  void _drawNumber() {
    try {
      final n = int.tryParse(_numberController.text.trim());
      if (n == null || n < 1 || n > 75) {
        Get.snackbar('Número inválido', 'Informe entre 1 e 75', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      if (_ws == null) {
        Get.snackbar('Erro', 'Serviço não inicializado', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      _ws!.sendEvent(BingoEvent(BingoEventType.drawNumber, {'number': n}));
      _numberController.clear();
    } catch (e) {
      // print('Erro ao sortear número: $e');
      Get.snackbar('Erro', 'Não foi possível sortear o número', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _reset() {
    try {
      if (_ws == null) {
        Get.snackbar('Erro', 'Serviço não inicializado', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      _ws!.sendEvent(BingoEvent(BingoEventType.resetGame, {}));
    } catch (e) {
      // print('Erro ao resetar jogo: $e');
      Get.snackbar('Erro', 'Não foi possível resetar o jogo', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _setPrize() {
    try {
      final title = _prizeTitle.text.trim();
      final image = _prizeImage.text.trim();
      if (title.isEmpty || image.isEmpty) {
        Get.snackbar('Dados incompletos', 'Informe título e URL da imagem', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      if (_ws == null) {
        Get.snackbar('Erro', 'Serviço não inicializado', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      _ws!.sendEvent(BingoEvent(BingoEventType.setPrize, {
         'id': id,
         'title': title,
         'imageUrl': image,
       }));
      Get.snackbar('Prêmio atualizado', 'Divulgado aos clientes', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      // print('Erro ao definir prêmio: $e');
      Get.snackbar('Erro', 'Não foi possível definir o prêmio', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pasteImageUrl() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final txt = data?.text?.trim();
      if (txt != null && txt.isNotEmpty) {
        setState(() {
          _prizeImage.text = txt;
          _imagePreviewUrl = txt;
        });
      } else {
        Get.snackbar('Área de transferência vazia', 'Copie uma URL de imagem e tente novamente', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      // print('Erro ao colar URL da imagem: $e');
      Get.snackbar('Erro', 'Não foi possível colar a URL da imagem', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('🎨 Construindo tela admin do bingo - Connected: $_connected, WS: ${_ws != null}');
    
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _accentColor),
    );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Admin - Bingo'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_connected ? Icons.wifi : Icons.wifi_off),
              onPressed: () {
                if (_ws != null) {
                  _ws!.connect();
                }
              },
            ),
          ],
        ),
        body: _ws == null 
          ? _buildLoadingScreen()
          : _connected 
            ? _buildAdminPanel() 
            : _buildConnectionStatus(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Inicializando serviço do bingo...'),
          const SizedBox(height: 8),
          Text('Tentando conectar ao Supabase...', 
               style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Forçar criação do serviço e mostrar tela de conexão
              setState(() {
                _ws = null;
                _connected = false;
              });
            },
            child: const Text('Prosseguir sem conexão'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _retryInitialization,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Desconectado do servidor'),
          const SizedBox(height: 8),
          const Text('Você pode usar o painel em modo offline'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retryInitialization,
            child: const Text('Tentar reconectar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Mostrar painel mesmo desconectado
              setState(() => _connected = true);
            },
            child: const Text('Usar modo offline'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    // print('🎨 Construindo painel admin do bingo');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Chip(
              avatar: Icon(_connected ? Icons.wifi : Icons.wifi_off, color: _connected ? Colors.green : Colors.red),
              label: Text(_connected ? 'Conectado ao servidor' : 'Desconectado'),
            ),
          ]),
          const SizedBox(height: 12),

          Text('Cor de destaque', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((c) {
              final selected = c.value == _accentColor.value;
              return ChoiceChip(
                label: const Text(' '),
                selected: selected,
                selectedColor: c.withOpacity(0.25),
                backgroundColor: c.withOpacity(0.1),
                showCheckmark: true,
                onSelected: (_) => setState(() => _accentColor = c),
                avatar: CircleAvatar(backgroundColor: c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Números sorteados', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (_drawnNumbers.isEmpty)
                    const ListTile(leading: Icon(Icons.info_outline), title: Text('Nenhum número sorteado ainda'))
                  else Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _drawnNumbers
                        .map((n) => Chip(label: Text(n.toString()), backgroundColor: _accentColor.withOpacity(0.15)))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configurar prêmio', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(controller: _prizeTitle, decoration: const InputDecoration(labelText: 'Título do prêmio')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _prizeImage, decoration: const InputDecoration(labelText: 'URL da imagem do prêmio'))),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(onPressed: _pasteImageUrl, icon: const Icon(Icons.paste), label: const Text('Colar URL')),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePreviewUrl == null
                        ? const Center(child: Text('Prévia da imagem do prêmio'))
                        : Image.network(
                            _imagePreviewUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => const Center(child: Text('Prévia indisponível')),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(onPressed: _setPrize, icon: const Icon(Icons.emoji_events), label: const Text('Aplicar prêmio')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sorteio de números', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _numberController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número (1-75)'))),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(onPressed: _drawNumber, icon: const Icon(Icons.casino), label: const Text('Sortear')),
                  ]),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('Novo jogo')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ganhadores', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (_winners.isEmpty)
                    const ListTile(leading: Icon(Icons.info_outline), title: Text('Nenhum ganhador até o momento'))
                  else ..._winners.map((w) => ListTile(leading: const Icon(Icons.emoji_events), title: Text(w))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}