import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/models/media_item.dart';
import '../../core/models/subtitle_item.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'auraplayer.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. media_files table
    await db.execute('''
      CREATE TABLE media_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        duration INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL,
        size INTEGER NOT NULL DEFAULT 0,
        date_added INTEGER NOT NULL,
        last_position INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        thumbnail_path TEXT
      )
    ''');

    // Indices for ultra-fast listing, filtering & sorting
    await db.execute('CREATE INDEX idx_media_type ON media_files(type)');
    await db.execute('CREATE INDEX idx_media_path ON media_files(path)');
    await db.execute('CREATE INDEX idx_media_date ON media_files(date_added DESC)');
    await db.execute('CREATE INDEX idx_media_favorite ON media_files(is_favorite)');
    await db.execute('CREATE INDEX idx_media_last_pos ON media_files(last_position DESC)');

    // 2. subtitle_files table
    await db.execute('''
      CREATE TABLE subtitle_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        is_ai_generated INTEGER NOT NULL DEFAULT 0,
        format TEXT NOT NULL DEFAULT 'srt',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (media_id) REFERENCES media_files(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_subtitle_media_id ON subtitle_files(media_id)');

    // 3. app_settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // --- Media CRUD ---

  Future<List<MediaItem>> getMediaList({
    MediaType? type,
    bool? favoritesOnly,
    String? searchQuery,
    String sortBy = 'date_added',
    bool ascending = false,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    if (favoritesOnly == true) {
      whereClauses.add('is_favorite = 1');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR artist LIKE ? OR album LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final orderDirection = ascending ? 'ASC' : 'DESC';
    final orderBy = '$sortBy $orderDirection';

    final maps = await db.query(
      'media_files',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return maps.map((m) => MediaItem.fromMap(m)).toList();
  }

  Future<List<MediaItem>> getRecentMedia({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'media_files',
      where: 'last_position > 0',
      orderBy: 'date_added DESC',
      limit: limit,
    );
    return maps.map((m) => MediaItem.fromMap(m)).toList();
  }

  Future<int> insertOrUpdateMedia(MediaItem item) async {
    final db = await database;
    return await db.insert(
      'media_files',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchInsertOrUpdateMedia(List<MediaItem> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'media_files',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore, // preserve existing last_position/favorite
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateLastPosition(int id, int positionMs) async {
    final db = await database;
    await db.update(
      'media_files',
      {'last_position': positionMs},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> toggleFavorite(int id) async {
    final db = await database;
    final item = await db.query(
      'media_files',
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (item.isEmpty) return false;

    final current = (item.first['is_favorite'] as int? ?? 0) == 1;
    final next = !current;
    await db.update(
      'media_files',
      {'is_favorite': next ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return next;
  }

  Future<void> deleteMedia(int id) async {
    final db = await database;
    await db.delete(
      'media_files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Subtitle CRUD ---

  Future<int> insertSubtitle(SubtitleItem subtitle) async {
    final db = await database;
    return await db.insert(
      'subtitle_files',
      subtitle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SubtitleItem>> getSubtitlesForMedia(int mediaId) async {
    final db = await database;
    final maps = await db.query(
      'subtitle_files',
      where: 'media_id = ?',
      whereArgs: [mediaId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SubtitleItem.fromMap(m)).toList();
  }

  // --- Settings CRUD ---

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
