import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_offline.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cache_data(
        key TEXT PRIMARY KEY,
        json_data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        json_payload TEXT
      )
    ''');
  }

  // --- Caching Methods ---

  Future<void> saveCache(String key, dynamic data) async {
    final db = await database;
    await db.insert('cache_data', {
      'key': key,
      'json_data': json.encode(data),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<dynamic> getCache(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cache_data',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return json.decode(maps.first['json_data'] as String);
    }
    return null;
  }

  // --- Pending Transactions Methods ---

  Future<int> savePendingTransaction(Map<String, dynamic> payload) async {
    final db = await database;
    return await db.insert('pending_transactions', {
      'timestamp': DateTime.now().toIso8601String(),
      'json_payload': json.encode(payload),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_transactions',
      orderBy: 'id ASC',
    );

    return maps.map((row) {
      final payload =
          json.decode(row['json_payload'] as String) as Map<String, dynamic>;
      return <String, dynamic>{
        'id': row['id'],
        'timestamp': row['timestamp'],
        ...payload,
      };
    }).toList();
  }

  Future<void> deletePendingTransaction(int id) async {
    final db = await database;
    await db.delete('pending_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingTransactionsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM pending_transactions',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
