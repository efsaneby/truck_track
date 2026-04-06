import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('truck_track.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Versiyonu 4'e yükselttik
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // GELİŞTİRME AŞAMASINDA EN GARANTİ YOL:
        // Eğer versiyon değişirse eski tabloyu sil ve onCreate'i tekrar çalıştır.
        if (oldVersion < 4) {
          await db.execute("DROP TABLE IF EXISTS mesailer");
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mesailer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarih TEXT NOT NULL,
        toplamSaat REAL NOT NULL DEFAULT 0.0,
        geceSaati REAL NOT NULL DEFAULT 0.0,
        konaklamaGun INTEGER NOT NULL DEFAULT 0,
        kazanc REAL NOT NULL DEFAULT 0.0
      )
    ''');
  }

  Future<int> mesaiKaydet(Map<String, dynamic> satir) async {
    final db = await instance.database;
    return await db.insert('mesailer', satir);
  }

  Future<List<Map<String, dynamic>>> tumMesaileriGetir() async {
    final db = await instance.database;
    return await db.query('mesailer', orderBy: 'tarih DESC');
  }

  Future<int> mesaiSil(int id) async {
    final db = await instance.database;
    return await db.delete('mesailer', where: 'id = ?', whereArgs: [id]);
  }
}
