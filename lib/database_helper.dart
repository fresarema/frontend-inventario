import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'inventario.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE productos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            codigo TEXT NOT NULL,
            cantidad INTEGER NOT NULL,
            fecha_captura TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  Future<int> insertarProducto(Map<String, dynamic> producto) async {
    Database db = await database;
    return await db.insert('productos', producto);
  }

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    Database db = await database;
    return await db.query('productos');
  }

  Future<void> vaciarInventario() async {
    Database db = await database;
    await db.delete('productos');
  }
}