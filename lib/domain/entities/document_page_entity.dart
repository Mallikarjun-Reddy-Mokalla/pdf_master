import 'package:equatable/equatable.dart';

class DocumentPageEntity extends Equatable {
  final int? id;
  final int documentId;
  final String imagePath;
  final int pageOrder;
  final int rotation;
  final String filterType;

  const DocumentPageEntity({
    this.id,
    required this.documentId,
    required this.imagePath,
    required this.pageOrder,
    this.rotation = 0,
    this.filterType = 'original',
  });

  DocumentPageEntity copyWith({
    int? id,
    int? documentId,
    String? imagePath,
    int? pageOrder,
    int? rotation,
    String? filterType,
  }) {
    return DocumentPageEntity(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      imagePath: imagePath ?? this.imagePath,
      pageOrder: pageOrder ?? this.pageOrder,
      rotation: rotation ?? this.rotation,
      filterType: filterType ?? this.filterType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        documentId,
        imagePath,
        pageOrder,
        rotation,
        filterType,
      ];
}

