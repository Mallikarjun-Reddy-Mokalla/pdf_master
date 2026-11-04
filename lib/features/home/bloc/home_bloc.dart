import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../../../core/storage/app_storage_directory.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/document_entity.dart';
import '../../../domain/repositories/document_repository.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DocumentRepository repository;
  final FileService fileService;
  final PdfProcessor pdfProcessor;

  HomeBloc({
    required this.repository,
    required this.fileService,
    required this.pdfProcessor,
  }) : super(const HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SearchDocumentsEvent>(_onSearchDocuments);
    on<ClearSearchEvent>(_onClearSearch);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<DeleteDocumentEvent>(_onDeleteDocument);
    on<RenameDocumentEvent>(_onRenameDocument);
    on<ImportPdfEvent>(_onImportPdf);
    on<QuickConvertImagesEvent>(_onQuickConvertImages);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(const HomeLoading());
      final recentFiles = await repository.getRecentFiles(limit: 10);
      final favoriteFiles = await repository.getFavoriteDocuments();
      final totalStorage = await repository.getTotalStorageUsed();

      emit(HomeLoaded(
        recentFiles: recentFiles,
        favoriteFiles: favoriteFiles,
        totalStorageBytes: totalStorage,
      ));
    } catch (e) {
      emit(HomeError('Failed to load documents: ${e.toString()}'));
    }
  }

  Future<void> _onSearchDocuments(
    SearchDocumentsEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final currentState = state as HomeLoaded;

    if (event.query.trim().isEmpty) {
      emit(currentState.copyWith(
        isSearching: false,
        searchQuery: '',
        searchResults: [],
      ));
      return;
    }

    try {
      final results = await repository.searchDocuments(event.query);
      emit(currentState.copyWith(
        isSearching: true,
        searchQuery: event.query,
        searchResults: results,
      ));
    } catch (e) {
      emit(HomeError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final currentState = state as HomeLoaded;
    emit(currentState.copyWith(
      isSearching: false,
      searchQuery: '',
      searchResults: [],
    ));
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await repository.toggleFavorite(event.documentId, event.isFavorite);
      add(const LoadHomeData());
    } catch (e) {
      emit(HomeError('Failed to update favorite: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocumentEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await repository.deleteDocument(event.documentId);
      add(const LoadHomeData());
    } catch (e) {
      emit(HomeError('Failed to delete document: ${e.toString()}'));
    }
  }

  Future<void> _onRenameDocument(
    RenameDocumentEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final doc = await repository.getDocumentById(event.documentId);
      if (doc != null) {
        final sanitizedName = FileUtils.sanitizeFileName(event.newName);
        final currentFile = File(doc.filePath);
        final dir = currentFile.parent;
        final extension = FileUtils.getFileExtension(doc.filePath);
        final newPath = p.join(dir.path, '$sanitizedName.$extension');

        if (await currentFile.exists()) {
          await currentFile.rename(newPath);
        }

        final updated = doc.copyWith(
          name: sanitizedName,
          filePath: newPath,
          updatedAt: DateTime.now(),
        );
        await repository.updateDocument(updated);
        add(const LoadHomeData());
      }
    } catch (e) {
      emit(HomeError('Failed to rename document: ${e.toString()}'));
    }
  }

  Future<void> _onImportPdf(
    ImportPdfEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final pickedPaths = await fileService.pickPdfFiles(allowMultiple: true);
      if (pickedPaths.isNotEmpty) {
        for (final path in pickedPaths) {
          await fileService.importPdfToApp(path);
        }
        add(const LoadHomeData());
      }
    } catch (e) {
      emit(HomeError('Failed to import PDF: ${e.toString()}'));
    }
  }

  Future<void> _onQuickConvertImages(
    QuickConvertImagesEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final pickedImages = await fileService.pickImages(allowMultiple: true);
      if (pickedImages.isEmpty) return;

      final convertedDir = await AppStorageDirectory.getConvertedDirectory();
      final docName = 'Converted_${DateTime.now().millisecondsSinceEpoch}';
      final outputPath = p.join(convertedDir.path, '$docName.pdf');

      await pdfProcessor.imagesToPdf(pickedImages, outputPath);

      final outputFile = File(outputPath);
      final fileSize = await outputFile.length();
      final now = DateTime.now();

      final doc = DocumentEntity(
        name: docName,
        filePath: outputPath,
        fileType: 'pdf',
        fileSize: fileSize,
        pageCount: pickedImages.length,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await repository.insertDocument(doc);
      await repository.recordRecentFile(saved.id!);
      add(const LoadHomeData());
    } catch (e) {
      emit(HomeError('Image to PDF conversion failed: ${e.toString()}'));
    }
  }
}
