import '../../domain/entities/recent_file_entity.dart';
import '../database/database_tables.dart';
import 'document_model.dart';

class RecentFileModel extends RecentFileEntity {
  const RecentFileModel({
    super.id,
    required super.documentId,
    required super.lastOpened,
    super.document,
  });

  factory RecentFileModel.fromMap(Map<String, dynamic> map, [DocumentModel? doc]) {
    return RecentFileModel(
      id: map[DatabaseTables.colRecentId] as int?,
      documentId: map[DatabaseTables.colRecentDocId] as int,
      lastOpened: DateTime.parse(map[DatabaseTables.colRecentLastOpened] as String),
      document: doc,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DatabaseTables.colRecentId: id,
      DatabaseTables.colRecentDocId: documentId,
      DatabaseTables.colRecentLastOpened: lastOpened.toIso8601String(),
    };
  }
}

