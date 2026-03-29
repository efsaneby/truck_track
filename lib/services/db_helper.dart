import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  // Bu sınıfın tek bir kopyası olmalı (Singleton)
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  // Deftere (Database) ulaşmak için kapı
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('truck_track.db');
    return _database!;
  }

  // Defteri telefonda oluşturma
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate:
          _createDB, // Defter ilk defa açılıyorsa sayfaları çiz (Tablo oluştur)
    );
  }

  // Defterin sayfalarını (Tabloları) tasarlıyoruz
  Future _createDB(Database db, int version) async {
    // Mesai kayıtları tablosu
    await db.execute('''
      CREATE TABLE mesailer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarih TEXT NOT NULL,
        toplamSaat REAL NOT NULL,
        geceSaati REAL NOT NULL,
        konaklamaGun INTEGER NOT NULL,
        kazanc REAL NOT NULL
      )
    ''');
  }

  // 1. KAYDETME FONKSİYONU
  Future<int> mesaiKaydet(Map<String, dynamic> satir) async {
    final db = await instance.database;
    // 'mesailer' tablosuna satırı ekle
    return await db.insert('mesailer', satir);
  }

  // 2. OKUMA FONKSİYONU (Tüm kayıtları getir)
  Future<List<Map<String, dynamic>>> tumMesaileriGetir() async {
    final db = await instance.database;
    // Tarihe göre sıralı getir
    return await db.query('mesailer', orderBy: 'tarih DESC');
  }

  Future<int> mesaiSil(int id) async {
    final db = await instance.database;
    return await db.delete('mesailer', where: 'id = ?', whereArgs: [id]);
  }
}
