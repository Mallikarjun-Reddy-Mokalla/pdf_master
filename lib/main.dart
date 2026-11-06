import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/storage/app_storage_directory.dart';
import 'data/database/app_database.dart';
import 'data/repositories/document_repository_impl.dart';
import 'services/ad_service.dart';
import 'services/file_service.dart';
import 'services/pdf_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize storage directory hierarchy
  await AppStorageDirectory.getBaseDirectory();

  // Initialize SQLite Database
  final databaseProvider = AppDatabase.instance;
  await databaseProvider.database;

  // Initialize Repositories and Services
  final documentRepository = DocumentRepositoryImpl(dbProvider: databaseProvider);
  final fileService = FileService(repository: documentRepository);
  final pdfProcessor = SyncfusionPdfProcessor();

  // Initialize Google Mobile Ads with live release ad units
  await AdService.instance.initialize();

  runApp(
    PdfMasterApp(
      documentRepository: documentRepository,
      fileService: fileService,
      pdfProcessor: pdfProcessor,
    ),
  );
}
