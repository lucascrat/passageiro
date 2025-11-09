import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BingoDatabaseImpl {
  static Database? _db;

  static Future<Database> _instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'bingo.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bingo_card (
          id INTEGER PRIMARY KEY,
          numbers TEXT,
          marked TEXT
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prize (
          id TEXT PRIMARY KEY,
          title TEXT,
          imageUrl TEXT
        );
      ''');
    });
    return _db!;
  }

  Future<void> saveCard(String numbersJson, String markedJson) async {
    final db = await _instance();
    await db.insert('bingo_card', {'id': 1, 'numbers': numbersJson, 'marked': markedJson},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>?> loadCard() async {
    final db = await _instance();
    final rows = await db.query('bingo_card', where: 'id = 1');
    if (rows.isEmpty) return null;
    return {'numbers': rows.first['numbers'] as String, 'marked': rows.first['marked'] as String};
  }

  Future<void> savePrize(String id, String title, String imageUrl) async {
    final db = await _instance();
    await db.insert('prize', {'id': id, 'title': title, 'imageUrl': imageUrl},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>?> loadPrize() async {
    final db = await _instance();
    final rows = await db.query('prize');
    if (rows.isEmpty) return null;
    final r = rows.first;
    return {'id': r['id'] as String, 'title': r['title'] as String, 'imageUrl': r['imageUrl'] as String};
  }
}