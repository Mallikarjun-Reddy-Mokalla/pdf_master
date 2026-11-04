import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/storage/app_storage_directory.dart';
import 'database_tables.dart';

class AppDatabase {
  static const String _dbName = 'pdf_master.db';
  static const int _dbVersion = 1;

  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbDir = await AppStorageDirectory.getDatabaseDirectory();
    final dbPath = p.join(dbDir.path, _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enforce foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migration hooks for future versions
      },
    );
  }

  Future<void> _createTables(Database db) async {
    final batch = db.batch();
    batch.execute(DatabaseTables.createTableDocuments);
    batch.execute(DatabaseTables.createTableDocumentPages);
    batch.execute(DatabaseTables.createTableRecentFiles);
    batch.execute(DatabaseTables.createTableUserSettings);
    batch.execute(DatabaseTables.createTablePurchaseCache);
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

