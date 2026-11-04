import 'package:equatable/equatable.dart';
import '../../../domain/entities/document_entity.dart';
import '../../../domain/entities/recent_file_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<RecentFileEntity> recentFiles;
  final List<DocumentEntity> favoriteFiles;
  final List<DocumentEntity> searchResults;
  final int totalStorageBytes;
  final bool isSearching;
  final String searchQuery;
  final String? message;

  const HomeLoaded({
    required this.recentFiles,
    required this.favoriteFiles,
    this.searchResults = const [],
    this.totalStorageBytes = 0,
    this.isSearching = false,
    this.searchQuery = '',
    this.message,
  });

  HomeLoaded copyWith({
    List<RecentFileEntity>? recentFiles,
    List<DocumentEntity>? favoriteFiles,
    List<DocumentEntity>? searchResults,
    int? totalStorageBytes,
    bool? isSearching,
    String? searchQuery,
    String? message,
  }) {
    return HomeLoaded(
      recentFiles: recentFiles ?? this.recentFiles,
      favoriteFiles: favoriteFiles ?? this.favoriteFiles,
      searchResults: searchResults ?? this.searchResults,
      totalStorageBytes: totalStorageBytes ?? this.totalStorageBytes,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        recentFiles,
        favoriteFiles,
        searchResults,
        totalStorageBytes,
        isSearching,
        searchQuery,
        message,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

