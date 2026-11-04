import '../../domain/entities/document_entity.dart';
import '../database/database_tables.dart';

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    super.id,
    required super.name,
    required super.filePath,
    required super.fileType,
    required super.fileSize,
    required super.pageCount,
    required super.createdAt,
    required super.updatedAt,
    super.isFavorite,
    super.isDeleted,
  });

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      name: entity.name,
      filePath: entity.filePath,
      fileType: entity.fileType,
      fileSize: entity.fileSize,
      pageCount: entity.pageCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isFavorite: entity.isFavorite,
      isDeleted: entity.isDeleted,
    );
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map[DatabaseTables.colDocId] as int?,
      name: map[DatabaseTables.colDocName] as String,
      filePath: map[DatabaseTables.colDocFilePath] as String,
      fileType: map[DatabaseTables.colDocFileType] as String,
      fileSize: map[DatabaseTables.colDocFileSize] as int,
      pageCount: (map[DatabaseTables.colDocPageCount] as int?) ?? 1,
      createdAt: DateTime.parse(map[DatabaseTables.colDocCreatedAt] as String),
      updatedAt: DateTime.parse(map[DatabaseTables.colDocUpdatedAt] as String),
      isFavorite: (map[DatabaseTables.colDocIsFavorite] as int) == 1,
      isDeleted: (map[DatabaseTables.colDocIsDeleted] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DatabaseTables.colDocId: id,
      DatabaseTables.colDocName: name,
      DatabaseTables.colDocFilePath: filePath,
      DatabaseTables.colDocFileType: fileType,
      DatabaseTables.colDocFileSize: fileSize,
      DatabaseTables.colDocPageCount: pageCount,
      DatabaseTables.colDocCreatedAt: createdAt.toIso8601String(),
      DatabaseTables.colDocUpdatedAt: updatedAt.toIso8601String(),
      DatabaseTables.colDocIsFavorite: isFavorite ? 1 : 0,
      DatabaseTables.colDocIsDeleted: isDeleted ? 1 : 0,
    };
  }
}

