class DatabaseTables {
  DatabaseTables._();

  // Documents Table
  static const String tableDocuments = 'documents';
  static const String colDocId = 'id';
  static const String colDocName = 'name';
  static const String colDocFilePath = 'file_path';
  static const String colDocFileType = 'file_type';
  static const String colDocFileSize = 'file_size';
  static const String colDocPageCount = 'page_count';
  static const String colDocCreatedAt = 'created_at';
  static const String colDocUpdatedAt = 'updated_at';
  static const String colDocIsFavorite = 'is_favorite';
  static const String colDocIsDeleted = 'is_deleted';

  // Document Pages Table
  static const String tableDocumentPages = 'document_pages';
  static const String colPageId = 'id';
  static const String colPageDocId = 'document_id';
  static const String colPageImagePath = 'image_path';
  static const String colPageOrder = 'page_order';
  static const String colPageRotation = 'rotation';
  static const String colPageFilterType = 'filter_type';

  // Recent Files Table
  static const String tableRecentFiles = 'recent_files';
  static const String colRecentId = 'id';
  static const String colRecentDocId = 'document_id';
  static const String colRecentLastOpened = 'last_opened';

  // User Settings Table
  static const String tableUserSettings = 'user_settings';
  static const String colSettingId = 'id';
  static const String colSettingKey = 'setting_key';
  static const String colSettingValue = 'setting_value';

  // Purchase Cache Table
  static const String tablePurchaseCache = 'purchase_cache';
  static const String colPurchaseId = 'id';
  static const String colPurchaseEntitlement = 'entitlement';
  static const String colPurchaseExpiryDate = 'expiry_date';
  static const String colPurchaseLastVerified = 'last_verified';

  // SQL Schema Creation Statements
  static const String createTableDocuments = '''
    CREATE TABLE $tableDocuments (
      $colDocId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colDocName TEXT NOT NULL,
      $colDocFilePath TEXT NOT NULL,
      $colDocFileType TEXT NOT NULL,
      $colDocFileSize INTEGER NOT NULL,
      $colDocPageCount INTEGER NOT NULL DEFAULT 1,
      $colDocCreatedAt TEXT NOT NULL,
      $colDocUpdatedAt TEXT NOT NULL,
      $colDocIsFavorite INTEGER NOT NULL DEFAULT 0,
      $colDocIsDeleted INTEGER NOT NULL DEFAULT 0
    );
  ''';

  static const String createTableDocumentPages = '''
    CREATE TABLE $tableDocumentPages (
      $colPageId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colPageDocId INTEGER NOT NULL,
      $colPageImagePath TEXT NOT NULL,
      $colPageOrder INTEGER NOT NULL,
      $colPageRotation INTEGER NOT NULL DEFAULT 0,
      $colPageFilterType TEXT NOT NULL DEFAULT 'original',
      FOREIGN KEY ($colPageDocId) REFERENCES $tableDocuments ($colDocId) ON DELETE CASCADE
    );
  ''';

  static const String createTableRecentFiles = '''
    CREATE TABLE $tableRecentFiles (
      $colRecentId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colRecentDocId INTEGER NOT NULL UNIQUE,
      $colRecentLastOpened TEXT NOT NULL,
      FOREIGN KEY ($colRecentDocId) REFERENCES $tableDocuments ($colDocId) ON DELETE CASCADE
    );
  ''';

  static const String createTableUserSettings = '''
    CREATE TABLE $tableUserSettings (
      $colSettingId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colSettingKey TEXT NOT NULL UNIQUE,
      $colSettingValue TEXT NOT NULL
    );
  ''';

  static const String createTablePurchaseCache = '''
    CREATE TABLE $tablePurchaseCache (
      $colPurchaseId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colPurchaseEntitlement TEXT NOT NULL,
      $colPurchaseExpiryDate TEXT,
      $colPurchaseLastVerified TEXT NOT NULL
    );
  ''';
}

