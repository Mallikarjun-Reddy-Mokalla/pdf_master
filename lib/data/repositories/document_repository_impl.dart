import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../core/storage/app_storage_directory.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/recent_file_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../database/app_database.dart';
import '../database/database_tables.dart';
import '../models/document_model.dart';
import '../models/document_page_model.dart';
import '../models/recent_file_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final AppDatabase _dbProvider;

  DocumentRepositoryImpl({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  @override
  Future<List<DocumentEntity>> getAllDocuments() async {
    final db = await _dbProvider.database;
    final results = await db.query(
      DatabaseTables.tableDocuments,
      where: '${DatabaseTables.colDocIsDeleted} = 0',
      orderBy: '${DatabaseTables.colDocUpdatedAt} DESC',
    );
    return results.map((m) => DocumentModel.fromMap(m)).toList();
  }

  @override
  Future<List<DocumentEntity>> getFavoriteDocuments() async {
    final db = await _dbProvider.database;
    final results = await db.query(
      DatabaseTables.tableDocuments,
      where: '${DatabaseTables.colDocIsDeleted} = 0 AND ${DatabaseTables.colDocIsFavorite} = 1',
      orderBy: '${DatabaseTables.colDocUpdatedAt} DESC',
    );
    return results.map((m) => DocumentModel.fromMap(m)).toList();
  }

  @override
  Future<List<RecentFileEntity>> getRecentFiles({int limit = 10}) async {
    final db = await _dbProvider.database;
    // Join recent_files with documents
    final results = await db.rawQuery('''
      SELECT 
        r.${DatabaseTables.colRecentId} AS recent_id,
        r.${DatabaseTables.colRecentDocId} AS recent_doc_id,
        r.${DatabaseTables.colRecentLastOpened} AS recent_last_opened,
        d.${DatabaseTables.colDocId} AS doc_id,
        d.${DatabaseTables.colDocName} AS doc_name,
        d.${DatabaseTables.colDocFilePath} AS doc_file_path,
        d.${DatabaseTables.colDocFileType} AS doc_file_type,
        d.${DatabaseTables.colDocFileSize} AS doc_file_size,
        d.${DatabaseTables.colDocPageCount} AS doc_page_count,
        d.${DatabaseTables.colDocCreatedAt} AS doc_created_at,
        d.${DatabaseTables.colDocUpdatedAt} AS doc_updated_at,
        d.${DatabaseTables.colDocIsFavorite} AS doc_is_favorite,
        d.${DatabaseTables.colDocIsDeleted} AS doc_is_deleted
      FROM ${DatabaseTables.tableRecentFiles} r
      INNER JOIN ${DatabaseTables.tableDocuments} d 
        ON r.${DatabaseTables.colRecentDocId} = d.${DatabaseTables.colDocId}
      WHERE d.${DatabaseTables.colDocIsDeleted} = 0
      ORDER BY r.${DatabaseTables.colRecentLastOpened} DESC
      LIMIT ?
    ''', [limit]);

    final List<RecentFileEntity> list = [];
    for (final row in results) {
      final doc = DocumentModel(
        id: row['doc_id'] as int,
        name: row['doc_name'] as String,
        filePath: row['doc_file_path'] as String,
        fileType: row['doc_file_type'] as String,
        fileSize: row['doc_file_size'] as int,
        pageCount: (row['doc_page_count'] as int?) ?? 1,
        createdAt: DateTime.parse(row['doc_created_at'] as String),
        updatedAt: DateTime.parse(row['doc_updated_at'] as String),
        isFavorite: (row['doc_is_favorite'] as int) == 1,
        isDeleted: (row['doc_is_deleted'] as int) == 1,
      );

      list.add(RecentFileModel(
        id: row['recent_id'] as int,
        documentId: row['recent_doc_id'] as int,
        lastOpened: DateTime.parse(row['recent_last_opened'] as String),
        document: doc,
      ));
    }
    return list;
  }

  @override
  Future<DocumentEntity?> getDocumentById(int id) async {
    final db = await _dbProvider.database;
    final results = await db.query(
      DatabaseTables.tableDocuments,
      where: '${DatabaseTables.colDocId} = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return DocumentModel.fromMap(results.first);
  }

  @override
  Future<DocumentEntity> insertDocument(DocumentEntity document) async {
    final db = await _dbProvider.database;
    final model = DocumentModel.fromEntity(document);
    final id = await db.insert(
      DatabaseTables.tableDocuments,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return document.copyWith(id: id);
  }

  @override
  Future<void> updateDocument(DocumentEntity document) async {
    if (document.id == null) return;
    final db = await _dbProvider.database;
    final model = DocumentModel.fromEntity(document);
    await db.update(
      DatabaseTables.tableDocuments,
      model.toMap(),
      where: '${DatabaseTables.colDocId} = ?',
      whereArgs: [document.id],
    );
  }

  @override
  Future<void> deleteDocument(int id, {bool deleteFileFromDisk = true}) async {
    final db = await _dbProvider.database;
    if (deleteFileFromDisk) {
      final doc = await getDocumentById(id);
      if (doc != null) {
        final file = File(doc.filePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {
            // Ignore if already deleted
          }
        }
      }
    }

    // Cascade delete handles pages and recents due to foreign key constraints
    await db.delete(
      DatabaseTables.tableDocuments,
      where: '${DatabaseTables.colDocId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await _dbProvider.database;
    await db.update(
      DatabaseTables.tableDocuments,
      {
        DatabaseTables.colDocIsFavorite: isFavorite ? 1 : 0,
        DatabaseTables.colDocUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseTables.colDocId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> recordRecentFile(int documentId) async {
    final db = await _dbProvider.database;
    final nowIso = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO ${DatabaseTables.tableRecentFiles} 
        (${DatabaseTables.colRecentDocId}, ${DatabaseTables.colRecentLastOpened})
      VALUES (?, ?)
      ON CONFLICT(${DatabaseTables.colRecentDocId}) 
      DO UPDATE SET ${DatabaseTables.colRecentLastOpened} = ?
    ''', [documentId, nowIso, nowIso]);
  }

  @override
  Future<List<DocumentEntity>> searchDocuments(String query) async {
    final db = await _dbProvider.database;
    final cleanQuery = '%${query.trim().toLowerCase()}%';
    final results = await db.query(
      DatabaseTables.tableDocuments,
      where: '${DatabaseTables.colDocIsDeleted} = 0 AND LOWER(${DatabaseTables.colDocName}) LIKE ?',
      whereArgs: [cleanQuery],
      orderBy: '${DatabaseTables.colDocUpdatedAt} DESC',
    );
    return results.map((m) => DocumentModel.fromMap(m)).toList();
  }

  @override
  Future<void> insertPages(List<DocumentPageEntity> pages) async {
    final db = await _dbProvider.database;
    final batch = db.batch();
    for (final page in pages) {
      final model = DocumentPageModel.fromEntity(page);
      batch.insert(DatabaseTables.tableDocumentPages, model.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<DocumentPageEntity>> getPagesForDocument(int documentId) async {
    final db = await _dbProvider.database;
    final results = await db.query(
      DatabaseTables.tableDocumentPages,
      where: '${DatabaseTables.colPageDocId} = ?',
      whereArgs: [documentId],
      orderBy: '${DatabaseTables.colPageOrder} ASC',
    );
    return results.map((m) => DocumentPageModel.fromMap(m)).toList();
  }

  @override
  Future<void> deletePagesForDocument(int documentId) async {
    final db = await _dbProvider.database;
    await db.delete(
      DatabaseTables.tableDocumentPages,
      where: '${DatabaseTables.colPageDocId} = ?',
      whereArgs: [documentId],
    );
  }

  @override
  Future<int> getTotalStorageUsed() async {
    return await AppStorageDirectory.calculateTotalStorageUsed();
  }
}

