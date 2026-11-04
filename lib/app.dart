import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/document_repository.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/home/bloc/home_event.dart';
import 'features/home/presentation/screens/main_shell_screen.dart';
import 'services/file_service.dart';
import 'services/pdf_service.dart';

class PdfMasterApp extends StatelessWidget {
  final DocumentRepository documentRepository;
  final FileService fileService;
  final PdfProcessor pdfProcessor;

  const PdfMasterApp({
    super.key,
    required this.documentRepository,
    required this.fileService,
    required this.pdfProcessor,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DocumentRepository>.value(value: documentRepository),
        RepositoryProvider<FileService>.value(value: fileService),
        RepositoryProvider<PdfProcessor>.value(value: pdfProcessor),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              repository: documentRepository,
              fileService: fileService,
              pdfProcessor: pdfProcessor,
            )..add(const LoadHomeData()),
          ),
        ],
        child: MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MainShellScreen(),
        ),
      ),
    );
  }
}

