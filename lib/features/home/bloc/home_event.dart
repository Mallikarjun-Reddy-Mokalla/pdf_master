import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

class SearchDocumentsEvent extends HomeEvent {
  final String query;
  const SearchDocumentsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends HomeEvent {
  const ClearSearchEvent();
}

class ToggleFavoriteEvent extends HomeEvent {
  final int documentId;
  final bool isFavorite;
  const ToggleFavoriteEvent({required this.documentId, required this.isFavorite});

  @override
  List<Object?> get props => [documentId, isFavorite];
}

class DeleteDocumentEvent extends HomeEvent {
  final int documentId;
  const DeleteDocumentEvent(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class RenameDocumentEvent extends HomeEvent {
  final int documentId;
  final String newName;
  const RenameDocumentEvent({required this.documentId, required this.newName});

  @override
  List<Object?> get props => [documentId, newName];
}

class ImportPdfEvent extends HomeEvent {
  const ImportPdfEvent();
}

class QuickConvertImagesEvent extends HomeEvent {
  const QuickConvertImagesEvent();
}

