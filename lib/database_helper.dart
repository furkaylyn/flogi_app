import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    String path = join(await getDatabasesPath(), 'flogi_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Gelir/Gider tablosu
    await db.execute('''
      CREATE TABLE gelir_gider (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tur TEXT NOT NULL,
        kategori TEXT NOT NULL,
        miktar REAL NOT NULL,
        aciklama TEXT,
        tarih TEXT NOT NULL
      )
    ''');

    // Müşteri tablosu
    await db.execute('''
      CREATE TABLE musteriler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad TEXT NOT NULL,
        telefon TEXT,
        email TEXT,
        adres TEXT
      )
    ''');

    // Fatura tablosu
    await db.execute('''
      CREATE TABLE faturalar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        musteri_id INTEGER,
        tur TEXT NOT NULL,
        tutar REAL NOT NULL,
        tarih TEXT NOT NULL,
        aciklama TEXT,
        FOREIGN KEY (musteri_id) REFERENCES musteriler (id)
      )
    ''');

    // Ürün/Hizmet tablosu
    await db.execute('''
      CREATE TABLE urun_hizmet (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad TEXT NOT NULL,
        kategori TEXT NOT NULL,
        fiyat REAL NOT NULL,
        aciklama TEXT
      )
    ''');

    // Kasa/Banka tablosu
    await db.execute('''
      CREATE TABLE kasa_banka (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tur TEXT NOT NULL,
        hesap_adi TEXT NOT NULL,
        bakiye REAL NOT NULL,
        aciklama TEXT
      )
    ''');
  }

  // Gelir/Gider işlemleri
  Future<int> insertGelirGider(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('gelir_gider', row);
  }

  Future<List<Map<String, dynamic>>> getGelirGider() async {
    Database db = await database;
    return await db.query('gelir_gider', orderBy: 'tarih DESC');
  }

  Future<int> updateGelirGider(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'gelir_gider',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteGelirGider(int id) async {
    Database db = await database;
    return await db.delete(
      'gelir_gider',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Müşteri işlemleri
  Future<int> insertMusteri(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('musteriler', row);
  }

  Future<List<Map<String, dynamic>>> getMusteriler() async {
    Database db = await database;
    return await db.query('musteriler', orderBy: 'ad ASC');
  }

  Future<int> updateMusteri(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'musteriler',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteMusteri(int id) async {
    Database db = await database;
    return await db.delete(
      'musteriler',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fatura işlemleri
  Future<int> insertFatura(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('faturalar', row);
  }

  Future<List<Map<String, dynamic>>> getFaturalar() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT f.*, m.ad as musteri_adi 
      FROM faturalar f 
      LEFT JOIN musteriler m ON f.musteri_id = m.id 
      ORDER BY f.tarih DESC
    ''');
  }

  Future<int> updateFatura(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'faturalar',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteFatura(int id) async {
    Database db = await database;
    return await db.delete(
      'faturalar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ürün/Hizmet işlemleri
  Future<int> insertUrunHizmet(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('urun_hizmet', row);
  }

  Future<List<Map<String, dynamic>>> getUrunHizmet() async {
    Database db = await database;
    return await db.query('urun_hizmet', orderBy: 'ad ASC');
  }

  Future<int> updateUrunHizmet(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'urun_hizmet',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteUrunHizmet(int id) async {
    Database db = await database;
    return await db.delete(
      'urun_hizmet',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Kasa/Banka işlemleri
  Future<int> insertKasaBanka(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('kasa_banka', row);
  }

  Future<List<Map<String, dynamic>>> getKasaBanka() async {
    Database db = await database;
    return await db.query('kasa_banka', orderBy: 'hesap_adi ASC');
  }

  Future<int> updateKasaBanka(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'kasa_banka',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteKasaBanka(int id) async {
    Database db = await database;
    return await db.delete(
      'kasa_banka',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Raporlama için özel sorgular
  Future<double> getGelirToplami() async {
    Database db = await database;
    var result = await db.rawQuery('''
      SELECT SUM(miktar) as toplam 
      FROM gelir_gider 
      WHERE tur = 'Gelir'
    ''');
    return result.first['toplam'] as double? ?? 0.0;
  }

  Future<double> getGiderToplami() async {
    Database db = await database;
    var result = await db.rawQuery('''
      SELECT SUM(miktar) as toplam 
      FROM gelir_gider 
      WHERE tur = 'Gider'
    ''');
    return result.first['toplam'] as double? ?? 0.0;
  }
} 