import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_master/core/constants/app_colors.dart';
import 'package:pdf_master/core/constants/app_dimens.dart';
import 'package:pdf_master/core/constants/app_strings.dart';
import 'package:pdf_master/domain/entities/document_entity.dart';
import 'package:pdf_master/domain/repositories/document_repository.dart';
import 'package:pdf_master/features/home/bloc/home_bloc.dart';
import 'package:pdf_master/features/home/bloc/home_event.dart';
import 'package:pdf_master/services/file_service.dart';
import 'package:pdf_master/shared/dialogs/document_actions_dialog.dart';
import 'package:pdf_master/shared/widgets/custom_app_bar.dart';
import 'package:pdf_master/shared/widgets/empty_state_view.dart';
import 'package:pdf_master/shared/widgets/file_card_tile.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  int _filterIndex = 0; // 0: All, 1: PDFs, 2: Favorites
  List<DocumentEntity> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final repo = context.read<DocumentRepository>();
    List<DocumentEntity> docs;
    if (_filterIndex == 2) {
      docs = await repo.getFavoriteDocuments();
    } else {
      docs = await repo.getAllDocuments();
      if (_filterIndex == 1) {
        docs = docs.where((d) => d.fileType == 'pdf').toList();
      }
    }
    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  void _openDoc(DocumentEntity doc) async {
    final fileService = context.read<FileService>();
    final result = await fileService.openPdfFile(doc.filePath);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: ${result.message}')),
      );
    }
  }

  void _showOptions(DocumentEntity doc) {
    final fileService = context.read<FileService>();
    final repo = context.read<DocumentRepository>();

    DocumentActionsModal.show(
      context: context,
      document: doc,
      onOpen: () => _openDoc(doc),
      onShare: () => fileService.sharePdfFile(doc.filePath, text: doc.name),
      onPrint: () => fileService.printPdfFile(doc.filePath, doc.name),
      onRename: () {
        final ctrl = TextEditingController(text: doc.name);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rename Document'),
            content: TextField(controller: ctrl, autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
              ElevatedButton(
                onPressed: () {
                  final newName = ctrl.text.trim();
                  if (newName.isNotEmpty) {
                    context.read<HomeBloc>().add(
                          RenameDocumentEvent(documentId: doc.id!, newName: newName),
                        );
                    _loadFiles();
                  }
                  Navigator.pop(ctx);
                },
                child: const Text(AppStrings.save),
              ),
            ],
          ),
        );
      },
      onToggleFavorite: () async {
        await repo.toggleFavorite(doc.id!, !doc.isFavorite);
        _loadFiles();
      },
      onDelete: () async {
        await repo.deleteDocument(doc.id!);
        _loadFiles();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Document Library',
        subtitle: '${_documents.length} documents stored on device',
        showBottomDivider: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import PDF',
            onPressed: () async {
              final fileService = context.read<FileService>();
              final paths = await fileService.pickPdfFiles(allowMultiple: true);
              for (final p in paths) {
                await fileService.importPdfToApp(p);
              }
              _loadFiles();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Documents',
                  isSelected: _filterIndex == 0,
                  onTap: () {
                    setState(() => _filterIndex = 0);
                    _loadFiles();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'PDFs Only',
                  isSelected: _filterIndex == 1,
                  onTap: () {
                    setState(() => _filterIndex = 1);
                    _loadFiles();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Favorites',
                  isSelected: _filterIndex == 2,
                  onTap: () {
                    setState(() => _filterIndex = 2);
                    _loadFiles();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? EmptyStateView(
                        icon: Icons.folder_open_rounded,
                        title: 'No Documents',
                        message: 'Documents you create, scan, or import will be stored here.',
                        buttonText: 'Import PDF',
                        onButtonPressed: () async {
                          final fileService = context.read<FileService>();
                          final paths = await fileService.pickPdfFiles(allowMultiple: true);
                          for (final p in paths) {
                            await fileService.importPdfToApp(p);
                          }
                          _loadFiles();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFiles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            return FileCardTile(
                              document: doc,
                              onTap: () => _openDoc(doc),
                              onMoreTap: () => _showOptions(doc),
                              onFavoriteTap: () async {
                                final repo = context.read<DocumentRepository>();
                                await repo.toggleFavorite(doc.id!, !doc.isFavorite);
                                _loadFiles();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
