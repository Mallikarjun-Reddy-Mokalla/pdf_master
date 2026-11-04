import 'package:equatable/equatable.dart';

class DocumentEntity extends Equatable {
  final int? id;
  final String name;
  final String filePath;
  final String fileType; // 'pdf', 'image'
  final int fileSize;
  final int pageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final bool isDeleted;

  const DocumentEntity({
    this.id,
    required this.name,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.pageCount,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isDeleted = false,
  });

  DocumentEntity copyWith({
    int? id,
    String? name,
    String? filePath,
    String? fileType,
    int? fileSize,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isDeleted,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        filePath,
        fileType,
        fileSize,
        pageCount,
        createdAt,
        updatedAt,
        isFavorite,
        isDeleted,
      ];
}

