import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class PsnCacheDataSource({DatabaseFactory? factory, final String? _path}) {
  static const _titlesTable = 'psn_titles';
  static const _trophiesTable = 'psn_trophies';
  static const _earnedTable = 'psn_earned';
  static const _titlesKey = 'me';

  final DatabaseFactory _factory = factory ?? databaseFactory;
  Database? _db;

  Future<Database> _database() async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    final path =
        _path ?? p.join(await _factory.getDatabasesPath(), 'psn_cache.db');
    return _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _create),
    );
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_titlesTable (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        fetched_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_trophiesTable (
        np_communication_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        fetched_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_earnedTable (
        np_communication_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        fetched_at TEXT NOT NULL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>?> readTitles() =>
      _read(_titlesTable, 'id', _titlesKey);

  Future<void> writeTitles(List<Map<String, dynamic>> titles) =>
      _write(_titlesTable, 'id', _titlesKey, titles);

  Future<List<Map<String, dynamic>>?> readTrophies(String npCommunicationId) =>
      _read(_trophiesTable, 'np_communication_id', npCommunicationId);

  Future<void> writeTrophies(
    String npCommunicationId,
    List<Map<String, dynamic>> trophies,
  ) => _write(
    _trophiesTable,
    'np_communication_id',
    npCommunicationId,
    trophies,
  );

  Future<Set<int>?> readEarned(String npCommunicationId) async {
    final rows = await _read(
      _earnedTable,
      'np_communication_id',
      npCommunicationId,
    );
    if (rows == null) return null;
    return {for (final row in rows) (row['trophyId'] as num).toInt()};
  }

  Future<void> writeEarned(String npCommunicationId, Set<int> trophyIds) =>
      _write(_earnedTable, 'np_communication_id', npCommunicationId, [
        for (final id in trophyIds) {'trophyId': id},
      ]);

  Future<List<Map<String, dynamic>>?> _read(
    String table,
    String keyColumn,
    String key,
  ) async {
    final db = await _database();
    final rows = await db.query(
      table,
      columns: ['payload'],
      where: '$keyColumn = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (jsonDecode(rows.single['payload'] as String) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<void> _write(
    String table,
    String keyColumn,
    String key,
    List<Map<String, dynamic>> payload,
  ) async {
    final db = await _database();
    await db.insert(table, {
      keyColumn: key,
      'payload': jsonEncode(payload),
      'fetched_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
