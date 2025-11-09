class BingoDatabaseImpl {
  Map<String, String> _card = {};
  Map<String, String> _prize = {};

  Future<void> saveCard(String numbersJson, String markedJson) async {
    _card = {'numbers': numbersJson, 'marked': markedJson};
  }

  Future<Map<String, String>?> loadCard() async {
    if (_card.isEmpty) return null;
    return _card;
  }

  Future<void> savePrize(String id, String title, String imageUrl) async {
    _prize = {'id': id, 'title': title, 'imageUrl': imageUrl};
  }

  Future<Map<String, String>?> loadPrize() async {
    if (_prize.isEmpty) return null;
    return _prize;
  }
}