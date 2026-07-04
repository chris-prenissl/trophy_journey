import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ProgressLocalDataSource {
  ProgressLocalDataSource({DatabaseFactory? factory, this._path})
    : _factory = factory ?? databaseFactory;

  static const _table = 'progress';

  final DatabaseFactory _factory;
  final String? _path;
  Database? _db;

  Future<Database> _database() async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    final path =
        _path ??
        p.join(await _factory.getDatabasesPath(), 'trophy_progress.db');
    return _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE $_table (
            trophy_id TEXT PRIMARY KEY,
            achieved INTEGER NOT NULL,
            achieved_at TEXT
          )
        '''),
      ),
    );
  }

  Future<Set<String>> loadAchievedIds() async {
    final db = await _database();
    final rows = await db.query(
      _table,
      columns: ['trophy_id'],
      where: 'achieved = 1',
    );
    return rows.map((r) => r['trophy_id'] as String).toSet();
  }

  Future<void> saveAchieved(String trophyId, bool achieved) async {
    final db = await _database();
    await db.insert(_table, {
      'trophy_id': trophyId,
      'achieved': achieved ? 1 : 0,
      'achieved_at': achieved ? DateTime.now().toIso8601String() : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
