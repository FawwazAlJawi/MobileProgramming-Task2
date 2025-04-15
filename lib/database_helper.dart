import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        guid TEXT PRIMARY KEY,
        note TEXT,
        createdAt TEXT,
        modfiledAt TEXT
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    Database db = await database;
    return await db.query('tasks');
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'tasks',
      where: 'guid = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    Database db = await database;
    return await db.insert('tasks', task);
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    Database db = await database;
    return await db.update(
      'tasks',
      task,
      where: 'guid = ?',
      whereArgs: [task['guid']],
    );
  }

  Future<int> deleteTask(String id) async {
    Database db = await database;
    return await db.delete(
      'tasks',
      where: 'guid = ?',
      whereArgs: [id],
    );
  }
} 