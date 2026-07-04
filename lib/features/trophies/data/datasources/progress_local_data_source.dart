import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ProgressLocalDataSource {
  ProgressLocalDataSource({DatabaseFactory? factory, this._path})
    : _factory = factory ?? databaseFactory;

  static const _table = 'progress';

  /// Game id assigned to rows written before the schema tracked games
  /// (schema v1 shipped when the app was FFX-only).
  static const _legacyGameId = 'final-fantasy-x-hd';

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
        version: 2,
        onCreate: (db, version) => _createV2(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // v1 had no game_id and trophy_id as primary key; sqlite cannot
            // alter a primary key, so rebuild the table.
            await db.execute('ALTER TABLE $_table RENAME TO ${_table}_v1');
            await _createV2(db);
            await db.execute('''
              INSERT INTO $_table (game_id, trophy_id, achieved, achieved_at)
              SELECT '$_legacyGameId', trophy_id, achieved, achieved_at
              FROM ${_table}_v1
            ''');
            await db.execute('DROP TABLE ${_table}_v1');
          }
        },
      ),
    );
  }

  static Future<void> _createV2(Database db) => db.execute('''
        CREATE TABLE $_table (
          game_id TEXT NOT NULL,
          trophy_id TEXT NOT NULL,
          achieved INTEGER NOT NULL,
          achieved_at TEXT,
          PRIMARY KEY (game_id, trophy_id)
        )
      ''');

  Future<Set<String>> loadAchievedIds(String gameId) async {
    final db = await _database();
    final rows = await db.query(
      _table,
      columns: ['trophy_id'],
      where: 'achieved = 1 AND game_id = ?',
      whereArgs: [gameId],
    );
    return rows.map((r) => r['trophy_id'] as String).toSet();
  }

  Future<Map<String, Set<String>>> loadAllAchievedIds() async {
    final db = await _database();
    final rows = await db.query(
      _table,
      columns: ['game_id', 'trophy_id'],
      where: 'achieved = 1',
    );
    final result = <String, Set<String>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row['game_id'] as String, () => {})
          .add(row['trophy_id'] as String);
    }
    return result;
  }

  Future<void> saveAchieved(
    String gameId,
    String trophyId,
    bool achieved,
  ) async {
    final db = await _database();
    await db.insert(_table, {
      'game_id': gameId,
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
