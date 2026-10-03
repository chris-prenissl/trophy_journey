import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ProgressLocalDataSource({DatabaseFactory? factory, final String? _path}) {
  static const _table = 'earned';

  final DatabaseFactory _factory = factory ?? databaseFactory;
  Database? _db;

  Future<Database> _database() async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    final path =
        _path ??
        p.join(await _factory.getDatabasesPath(), 'trophy_progress.db');
    return _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _create),
    );
  }

  static Future<void> _create(Database db, int version) => db.execute('''
        CREATE TABLE $_table (
          game_id TEXT NOT NULL,
          trophy_id TEXT NOT NULL,
          PRIMARY KEY (game_id, trophy_id)
        )
      ''');

  Future<Map<String, Set<String>>> loadAllEarnedIds() async {
    final db = await _database();
    final rows = await db.query(_table, columns: ['game_id', 'trophy_id']);
    final result = <String, Set<String>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row['game_id'] as String, () => {})
          .add(row['trophy_id'] as String);
    }
    return result;
  }

  Future<void> replaceEarned(String gameId, Set<String> trophyIds) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete(_table, where: 'game_id = ?', whereArgs: [gameId]);
      final batch = txn.batch();
      for (final trophyId in trophyIds) {
        batch.insert(_table, {'game_id': gameId, 'trophy_id': trophyId});
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
