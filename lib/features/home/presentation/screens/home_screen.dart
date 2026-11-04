import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_master/core/constants/app_colors.dart';
import 'package:pdf_master/core/constants/app_dimens.dart';
import 'package:pdf_master/core/constants/app_strings.dart';
import 'package:pdf_master/domain/entities/document_entity.dart';
import 'package:pdf_master/features/home/bloc/home_bloc.dart';
import 'package:pdf_master/features/home/bloc/home_event.dart';
import 'package:pdf_master/features/home/bloc/home_state.dart';
import 'package:pdf_master/services/file_service.dart';
import 'package:pdf_master/shared/dialogs/document_actions_dialog.dart';
import 'package:pdf_master/shared/widgets/empty_state_view.dart';
import 'package:pdf_master/shared/widgets/file_card_tile.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/premium_banner_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_files_section.dart';
import '../widgets/storage_overview_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToScan;
  final VoidCallback onNavigateToTools;
  final VoidCallback onNavigateToFiles;

  const HomeScreen({
    super.key,
    required this.onNavigateToScan,
    required this.onNavigateToTools,
    required this.onNavigateToFiles,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(BuildContext context, DocumentEntity doc) {
    final controller = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != doc.name) {
                context.read<HomeBloc>().add(
                      RenameDocumentEvent(documentId: doc.id!, newName: newName),
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DocumentEntity doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to permanently delete "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<HomeBloc>().add(DeleteDocumentEvent(doc.id!));
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _openDocument(BuildContext context, DocumentEntity doc) async {
    final fileService = context.read<FileService>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await fileService.openPdfFile(doc.filePath);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open file: ${result.message}')),
      );
    }
  }

  void _shareDocument(BuildContext context, DocumentEntity doc) async {
    final fileService = context.read<FileService>();
    await fileService.sharePdfFile(doc.filePath, text: doc.name);
  }

  void _printDocument(BuildContext context, DocumentEntity doc) async {
    final fileService = context.read<FileService>();
    await fileService.printPdfFile(doc.filePath, doc.name);
  }

  void _showDocumentOptions(BuildContext context, DocumentEntity doc) {
    DocumentActionsModal.show(
      context: context,
      document: doc,
      onOpen: () => _openDocument(context, doc),
      onShare: () => _shareDocument(context, doc),
      onPrint: () => _printDocument(context, doc),
      onRename: () => _showRenameDialog(context, doc),
      onToggleFavorite: () {
        context.read<HomeBloc>().add(
              ToggleFavoriteEvent(documentId: doc.id!, isFavorite: !doc.isFavorite),
            );
      },
      onDelete: () => _showDeleteDialog(context, doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is HomeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(const LoadHomeData());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // App Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.space16,
                        AppDimens.space16,
                        AppDimens.space16,
                        AppDimens.space12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    AppStrings.appName,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    AppStrings.tagline,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              // Pro icon badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.offline_bolt_rounded, size: 16, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.space16),

                          // Search Bar
                          HomeSearchBar(
                            controller: _searchController,
                            onChanged: (query) {
                              context.read<HomeBloc>().add(SearchDocumentsEvent(query));
                            },
                            onClear: () {
                              context.read<HomeBloc>().add(const ClearSearchEvent());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Results or Standard Dashboard
                  if (state is HomeLoaded && state.isSearching) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.space16,
                          vertical: AppDimens.space8,
                        ),
                        child: Text(
                          'Search Results for "${state.searchQuery}" (${state.searchResults.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (state.searchResults.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyStateView(
                          icon: Icons.search_off_rounded,
                          title: 'No Documents Found',
                          message: 'Try checking for spelling or searching with a different term.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = state.searchResults[index];
                              return FileCardTile(
                                document: doc,
                                onTap: () => _openDocument(context, doc),
                                onMoreTap: () => _showDocumentOptions(context, doc),
                                onFavoriteTap: () {
                                  context.read<HomeBloc>().add(
                                        ToggleFavoriteEvent(
                                          documentId: doc.id!,
                                          isFavorite: !doc.isFavorite,
                                        ),
                                      );
                                },
                              );
                            },
                            childCount: state.searchResults.length,
                          ),
                        ),
                      ),
                  ] else ...[
                    // Storage Overview Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                        child: StorageOverviewCard(
                          totalBytes: (state is HomeLoaded) ? state.totalStorageBytes : 0,
                          onManageTap: widget.onNavigateToFiles,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppDimens.space16)),

                    // Quick Actions Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.quickActions,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimens.space12),

                            // Row 1: Quick Scan & Image to PDF
                            Row(
                              children: [
                                QuickActionCard(
                                  title: AppStrings.quickScan,
                                  subtitle: AppStrings.quickScanSubtitle,
                                  icon: Icons.document_scanner_rounded,
                                  iconColor: AppColors.primary,
                                  backgroundColor: AppColors.primaryLight,
                                  onTap: widget.onNavigateToScan,
                                ),
                                const SizedBox(width: AppDimens.space12),
                                QuickActionCard(
                                  title: AppStrings.imageToPdf,
                                  subtitle: AppStrings.imageToPdfSubtitle,
                                  icon: Icons.photo_library_rounded,
                                  iconColor: AppColors.orangeBadge,
                                  backgroundColor: const Color(0xFFFFEDE0),
                                  onTap: () {
                                    context.read<HomeBloc>().add(const QuickConvertImagesEvent());
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.space12),

                            // Row 2: PDF Tools & Import PDF
                            Row(
                              children: [
                                QuickActionCard(
                                  title: AppStrings.pdfTools,
                                  subtitle: AppStrings.pdfToolsSubtitle,
                                  icon: Icons.auto_awesome_mosaic_rounded,
                                  iconColor: AppColors.purpleBadge,
                                  backgroundColor: const Color(0xFFF3E8FF),
                                  onTap: widget.onNavigateToTools,
                                ),
                                const SizedBox(width: AppDimens.space12),
                                QuickActionCard(
                                  title: 'Import PDF',
                                  subtitle: 'From local storage',
                                  icon: Icons.file_upload_outlined,
                                  iconColor: AppColors.tealBadge,
                                  backgroundColor: const Color(0xFFE6FFFA),
                                  onTap: () {
                                    context.read<HomeBloc>().add(const ImportPdfEvent());
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppDimens.space16)),

                    // Pro Banner Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                        child: PremiumBannerCard(
                          onUpgradeTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PDF Master Pro: Lifetime & Subscription offerings available'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppDimens.space20)),

                    // Recent & Favorite Files Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                        child: (state is HomeLoaded)
                            ? RecentFilesSection(
                                recentFiles: state.recentFiles,
                                favoriteFiles: state.favoriteFiles,
                                onDocumentTap: (doc) => _openDocument(context, doc),
                                onMoreTap: (doc) => _showDocumentOptions(context, doc),
                                onToggleFavorite: (doc) {
                                  context.read<HomeBloc>().add(
                                        ToggleFavoriteEvent(
                                          documentId: doc.id!,
                                          isFavorite: !doc.isFavorite,
                                        ),
                                      );
                                },
                                onImportTap: () {
                                  context.read<HomeBloc>().add(const ImportPdfEvent());
                                },
                                onViewAllTap: widget.onNavigateToFiles,
                              )
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppDimens.space32),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: AppDimens.space32)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
