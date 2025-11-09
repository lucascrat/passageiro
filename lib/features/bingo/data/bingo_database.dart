import 'bingo_database_sqflite.dart' if (dart.library.html) 'bingo_database_memory.dart';

final BingoDatabaseImpl _impl = BingoDatabaseImpl();

class BingoDatabase {
  static Future<void> saveCard(String numbersJson, String markedJson) => _impl.saveCard(numbersJson, markedJson);
  static Future<Map<String, String>?> loadCard() => _impl.loadCard();
  static Future<void> savePrize(String id, String title, String imageUrl) => _impl.savePrize(id, title, imageUrl);
  static Future<Map<String, String>?> loadPrize() => _impl.loadPrize();
}