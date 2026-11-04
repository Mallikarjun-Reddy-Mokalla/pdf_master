import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/document_entity.dart';
import '../../../../domain/entities/recent_file_entity.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/file_card_tile.dart';

class RecentFilesSection extends StatefulWidget {
  final List<RecentFileEntity> recentFiles;
  final List<DocumentEntity> favoriteFiles;
  final Function(DocumentEntity) onDocumentTap;
  final Function(DocumentEntity) onMoreTap;
  final Function(DocumentEntity) onToggleFavorite;
  final VoidCallback onImportTap;
  final VoidCallback onViewAllTap;

  const RecentFilesSection({
    super.key,
    required this.recentFiles,
    required this.favoriteFiles,
    required this.onDocumentTap,
    required this.onMoreTap,
    required this.onToggleFavorite,
    required this.onImportTap,
    required this.onViewAllTap,
  });

  @override
  State<RecentFilesSection> createState() => _RecentFilesSectionState();
}

class _RecentFilesSectionState extends State<RecentFilesSection> {
  int _selectedTab = 0; // 0: Recents, 1: Favorites

  @override
  Widget build(BuildContext context) {
    final recentDocs = widget.recentFiles
        .where((r) => r.document != null)
        .map((r) => r.document!)
        .toList();

    final displayedDocs = _selectedTab == 0 ? recentDocs : widget.favoriteFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selector and "View All"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _TabButton(
                  title: AppStrings.recentFiles,
                  count: recentDocs.length,
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: AppDimens.space12),
                _TabButton(
                  title: AppStrings.favoriteFiles,
                  count: widget.favoriteFiles.length,
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.onViewAllTap,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                AppStrings.viewAll,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space12),

        // List or Empty state
        if (displayedDocs.isEmpty)
          EmptyStateView(
            icon: _selectedTab == 0 ? Icons.folder_open_rounded : Icons.star_border_rounded,
            title: _selectedTab == 0 ? AppStrings.noRecentFiles : 'No Favorite Documents',
            message: _selectedTab == 0
                ? AppStrings.noRecentFilesDesc
                : 'Star important documents to access them quickly here.',
            buttonText: _selectedTab == 0 ? 'Import PDF' : null,
            onButtonPressed: _selectedTab == 0 ? widget.onImportTap : null,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedDocs.length,
            itemBuilder: (context, index) {
              final doc = displayedDocs[index];
              return FileCardTile(
                document: doc,
                onTap: () => widget.onDocumentTap(doc),
                onMoreTap: () => widget.onMoreTap(doc),
                onFavoriteTap: () => widget.onToggleFavorite(doc),
              );
            },
          ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
