import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class JourneyLocalDataSource {
  JourneyLocalDataSource({DatabaseFactory? factory, this._databasePath})
    : _factory = factory ?? databaseFactory;

  static const _taskTable = 'journey_task_progress';
  static const _bookmarkTable = 'journey_bookmark';

  final DatabaseFactory _factory;
  final String? _databasePath;
  Database? _db;

  Future<Database> _database() async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    final databasePath =
        _databasePath ??
        path.join(await _factory.getDatabasesPath(), 'journey_progress.db');
    return _db = await _factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_taskTable (
              game_id TEXT NOT NULL,
              task_id TEXT NOT NULL,
              checked INTEGER NOT NULL,
              checked_at TEXT,
              PRIMARY KEY (game_id, task_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE $_bookmarkTable (
              game_id TEXT NOT NULL PRIMARY KEY,
              step_id TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<Set<String>> loadCheckedTaskIds(String gameId) async {
    final db = await _database();
    final rows = await db.query(
      _taskTable,
      columns: ['task_id'],
      where: 'checked = 1 AND game_id = ?',
      whereArgs: [gameId],
    );
    return rows.map((r) => r['task_id'] as String).toSet();
  }

  Future<void> saveTaskChecked(
    String gameId,
    String taskId,
    bool checked,
  ) async {
    final db = await _database();
    await db.insert(_taskTable, {
      'game_id': gameId,
      'task_id': taskId,
      'checked': checked ? 1 : 0,
      'checked_at': checked ? DateTime.now().toIso8601String() : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> loadBookmark(String gameId) async {
    final db = await _database();
    final rows = await db.query(
      _bookmarkTable,
      columns: ['step_id'],
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    return rows.isEmpty ? null : rows.first['step_id'] as String;
  }

  Future<void> saveBookmark(String gameId, String? stepId) async {
    final db = await _database();
    if (stepId == null) {
      await db.delete(
        _bookmarkTable,
        where: 'game_id = ?',
        whereArgs: [gameId],
      );
    } else {
      await db.insert(_bookmarkTable, {
        'game_id': gameId,
        'step_id': stepId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
