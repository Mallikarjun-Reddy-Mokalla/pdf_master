import '../../domain/entities/document_page_entity.dart';
import '../database/database_tables.dart';

class DocumentPageModel extends DocumentPageEntity {
  const DocumentPageModel({
    super.id,
    required super.documentId,
    required super.imagePath,
    required super.pageOrder,
    super.rotation,
    super.filterType,
  });

  factory DocumentPageModel.fromEntity(DocumentPageEntity entity) {
    return DocumentPageModel(
      id: entity.id,
      documentId: entity.documentId,
      imagePath: entity.imagePath,
      pageOrder: entity.pageOrder,
      rotation: entity.rotation,
      filterType: entity.filterType,
    );
  }

  factory DocumentPageModel.fromMap(Map<String, dynamic> map) {
    return DocumentPageModel(
      id: map[DatabaseTables.colPageId] as int?,
      documentId: map[DatabaseTables.colPageDocId] as int,
      imagePath: map[DatabaseTables.colPageImagePath] as String,
      pageOrder: map[DatabaseTables.colPageOrder] as int,
      rotation: (map[DatabaseTables.colPageRotation] as int?) ?? 0,
      filterType: (map[DatabaseTables.colPageFilterType] as String?) ?? 'original',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DatabaseTables.colPageId: id,
      DatabaseTables.colPageDocId: documentId,
      DatabaseTables.colPageImagePath: imagePath,
      DatabaseTables.colPageOrder: pageOrder,
      DatabaseTables.colPageRotation: rotation,
      DatabaseTables.colPageFilterType: filterType,
    };
  }
}

