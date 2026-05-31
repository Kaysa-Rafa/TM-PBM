import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'model_pegawai.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pegawai.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tb_pegawai(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            posisi TEXT NOT NULL,
            gaji INTEGER NOT NULL,
            foto TEXT,
            latitude REAL,
            longitude REAL,
            alamat TEXT
          )
        ''');
      },
    );
  }

  Future<int> insert(Pegawai pegawai) async {
    final db = await database;
    return db.insert('tb_pegawai', pegawai.toMap());
  }

  Future<List<Pegawai>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tb_pegawai');
    return List.generate(maps.length, (i) => Pegawai.fromMap(maps[i]));
  }

  Future<int> update(Pegawai pegawai) async {
    final db = await database;
    return db.update(
      'tb_pegawai',
      pegawai.toMap(),
      where: 'id = ?',
      whereArgs: [pegawai.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(
      'tb_pegawai',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}