// lib/model_dao.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ModelDao {
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final path = join(await getDatabasesPath(), 'mydatabase.db');
    return openDatabase(
      path,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE myTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fileName TEXT NOT NULL
        )
        ''');
      },
      version: 1,
    );
  }

  // Fix: Updated to accept a Map, matching what we send from the UI screen
  Future<void> insert(Map<String, dynamic> row) async {
    // Fix: Renamed local variable to 'database' to avoid colliding with the 'db' getter
    final database = await db; 
    
    // Fix: Insert the row into the database using the new variable name
    await database.insert('myTable', row);
  }

  
  Future<List<Map<String, dynamic>>> getAllModels() async {
    final database = await db;
    return await database.query('myTable');
  }

  Future<void> deleteModel(int id) async {
    final database = await db;
    await database.delete('myTable', where: 'id = ?', whereArgs: [id]);
  }

}