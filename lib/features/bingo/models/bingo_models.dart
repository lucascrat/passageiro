import 'dart:math';

class BingoCard {
  final String id;
  final List<List<int?>> numbers; // null for free space
  final List<List<bool>> marked;
  bool isLocked;

  BingoCard({
    required this.id, 
    required this.numbers, 
    required this.marked,
    this.isLocked = false,
  });

  factory BingoCard.standard({String? customId, bool isLocked = false}) {
    // B(1-15) I(16-30) N(31-45) G(46-60) O(61-75)
    final rand = Random();
    List<List<int?>> cols = [];
    for (int c = 0; c < 5; c++) {
      int start = 1 + c * 15;
      List<int> pool = List.generate(15, (i) => start + i);
      pool.shuffle(rand);
      cols.add(pool.take(5).map((e) => e).toList());
    }
    // transpose to rows
    List<List<int?>> rows = List.generate(5, (r) => List.generate(5, (c) => cols[c][r]));
    // free space center
    rows[2][2] = null;
    final marked = List.generate(5, (r) => List.generate(5, (c) => r == 2 && c == 2));
    return BingoCard(
      id: customId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      numbers: rows, 
      marked: marked,
      isLocked: isLocked,
    );
  }

  bool markIfMatch(int number) {
    if (isLocked) return false; // Não marcar se bloqueada
    
    bool changed = false;
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        final n = numbers[r][c];
        if (n != null && n == number) {
          marked[r][c] = true;
          changed = true;
        }
      }
    }
    return changed;
  }

  // Limpa todas as marcações da cartela, mantendo o espaço livre marcado
  void clearMarks() {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        marked[r][c] = (r == 2 && c == 2);
      }
    }
  }

  bool hasBingo() {
    if (isLocked) return false; // Não pode ter BINGO se bloqueada
    
    // rows
    for (int r = 0; r < 5; r++) {
      if (marked[r].every((m) => m)) return true;
    }
    // cols
    for (int c = 0; c < 5; c++) {
      bool all = true;
      for (int r = 0; r < 5; r++) {
        if (!marked[r][c]) { all = false; break; }
      }
      if (all) return true;
    }
    // diagonals
    if (List.generate(5, (i) => marked[i][i]).every((m) => m)) return true;
    if (List.generate(5, (i) => marked[i][4 - i]).every((m) => m)) return true;
    return false;
  }

  // Verifica se a cartela está totalmente preenchida (cartela cheia)
  bool isFullCard() {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (!marked[r][c]) return false;
      }
    }
    return true;
  }

  // Retorna um resumo detalhado das condições de vitória atingidas
  Map<String, dynamic> winSummary() {
    final rows = <int>[];
    final cols = <int>[];
    bool diagMain = true;
    bool diagAnti = true;

    for (int r = 0; r < 5; r++) {
      if (marked[r].every((m) => m)) rows.add(r);
    }
    for (int c = 0; c < 5; c++) {
      bool all = true;
      for (int r = 0; r < 5; r++) {
        if (!marked[r][c]) { all = false; break; }
      }
      if (all) cols.add(c);
    }

    for (int i = 0; i < 5; i++) {
      if (!marked[i][i]) { diagMain = false; break; }
    }
    for (int i = 0; i < 5; i++) {
      if (!marked[i][4 - i]) { diagAnti = false; break; }
    }

    return {
      'rows': rows, // índices 0..4
      'cols': cols, // índices 0..4
      'diagMain': diagMain,
      'diagAnti': diagAnti,
      'fullCard': isFullCard(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numbers': numbers,
      'marked': marked,
      'isLocked': isLocked,
    };
  }

  factory BingoCard.fromJson(Map<String, dynamic> json) {
    return BingoCard(
      id: json['id'],
      numbers: List<List<int?>>.from(
        json['numbers'].map((row) => List<int?>.from(row))
      ),
      marked: List<List<bool>>.from(
        json['marked'].map((row) => List<bool>.from(row))
      ),
      isLocked: json['isLocked'] ?? false,
    );
  }
}

class BingoCardManager {
  static const int maxCards = 10;
  final List<BingoCard> _cards = [];

  List<BingoCard> get cards => List.unmodifiable(_cards);
  int get cardCount => _cards.length;
  BingoCard get currentCard => _cards.isNotEmpty ? _cards[0] : BingoCard.standard();
  bool get canAddMore => _cards.length < maxCards;

  BingoCardManager() {
    // Gerar múltiplas cartelas pré-definidas (8 cartelas)
    _generateInitialCards();
  }

  void _generateInitialCards() {
    _cards.clear();
    
    // Primeira cartela sempre desbloqueada
    _cards.add(BingoCard.standard(isLocked: false));
    
    // Gerar 7 cartelas adicionais bloqueadas
    for (int i = 1; i < 8; i++) {
      _cards.add(BingoCard.standard(isLocked: true));
    }
  }

  void addCard([BingoCard? card, bool isLocked = false]) {
    if (canAddMore) {
      _cards.add(card ?? BingoCard.standard(isLocked: isLocked));
    }
  }

  void unlockCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _cards[index].isLocked = false;
    }
  }



  void markNumberOnAllCards(int number) {
    for (var card in _cards) {
      card.markIfMatch(number);
    }
  }

  // Limpa marcações em todas as cartelas
  void clearAllMarks() {
    for (var card in _cards) {
      card.clearMarks();
    }
  }

  List<BingoCard> getCardsWithBingo() {
    return _cards.where((card) => card.hasBingo()).toList();
  }

  void generateNewCard(int index) {
    if (index >= 0 && index < _cards.length) {
      final wasLocked = _cards[index].isLocked;
      _cards[index] = BingoCard.standard(isLocked: wasLocked);
    }
  }

  // Método para regenerar todas as cartelas mantendo estados de bloqueio
  void regenerateAllCards() {
    final lockStates = _cards.map((card) => card.isLocked).toList();
    _cards.clear();
    
    for (int i = 0; i < lockStates.length; i++) {
      _cards.add(BingoCard.standard(isLocked: lockStates[i]));
    }
  }

  // Bloqueia uma cartela específica
  void lockCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _cards[index].isLocked = true;
    }
  }

  // Garante que somente a cartela 0 (primeira) fique desbloqueada
  void lockAllExceptFirst() {
    for (int i = 0; i < _cards.length; i++) {
      _cards[i].isLocked = i != 0 ? true : false;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'cards': _cards.map((card) => card.toJson()).toList(),
    };
  }

  factory BingoCardManager.fromJson(Map<String, dynamic> json) {
    final manager = BingoCardManager();
    manager._cards.clear();
    
    if (json['cards'] != null) {
      for (var cardJson in json['cards']) {
        manager._cards.add(BingoCard.fromJson(cardJson));
      }
    }
    
    // Se não há cartelas salvas ou há menos de 8, gerar as iniciais
    if (manager._cards.isEmpty || manager._cards.length < 8) {
      manager._generateInitialCards();
    }
    
    return manager;
  }
}

class Prize {
  final String id;
  final String imageUrl;
  final String title;
  final String value;
  
  Prize({
    required this.id, 
    required this.imageUrl, 
    required this.title,
    this.value = '',
  });
}

enum BingoEventType { drawNumber, resetGame, setPrize, claimWin, announceWinner, syncState }

class BingoEvent {
  final BingoEventType type;
  final Map<String, dynamic> data;
  BingoEvent(this.type, this.data);
}