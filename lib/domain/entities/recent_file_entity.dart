import 'package:equatable/equatable.dart';
import 'document_entity.dart';

class RecentFileEntity extends Equatable {
  final int? id;
  final int documentId;
  final DateTime lastOpened;
  final DocumentEntity? document;

  const RecentFileEntity({
    this.id,
    required this.documentId,
    required this.lastOpened,
    this.document,
  });

  @override
  List<Object?> get props => [id, documentId, lastOpened, document];
}

