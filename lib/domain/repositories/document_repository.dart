import '../entities/document_entity.dart';
import '../entities/document_page_entity.dart';
import '../entities/recent_file_entity.dart';

abstract class DocumentRepository {
  Future<List<DocumentEntity>> getAllDocuments();
  Future<List<DocumentEntity>> getFavoriteDocuments();
  Future<List<RecentFileEntity>> getRecentFiles({int limit = 10});
  Future<DocumentEntity?> getDocumentById(int id);
  Future<DocumentEntity> insertDocument(DocumentEntity document);
  Future<void> updateDocument(DocumentEntity document);
  Future<void> deleteDocument(int id, {bool deleteFileFromDisk = true});
  Future<void> toggleFavorite(int id, bool isFavorite);
  Future<void> recordRecentFile(int documentId);
  Future<List<DocumentEntity>> searchDocuments(String query);

  // Pages
  Future<void> insertPages(List<DocumentPageEntity> pages);
  Future<List<DocumentPageEntity>> getPagesForDocument(int documentId);
  Future<void> deletePagesForDocument(int documentId);

  // Storage calculation
  Future<int> getTotalStorageUsed();
}

