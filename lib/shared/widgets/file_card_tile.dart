import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/file_utils.dart';
import '../../domain/entities/document_entity.dart';

class FileCardTile extends StatelessWidget {
  final DocumentEntity document;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onFavoriteTap;

  const FileCardTile({
    super.key,
    required this.document,
    required this.onTap,
    this.onMoreTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = document.fileType.toLowerCase() == 'pdf';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space12),
            child: Row(
              children: [
                // Icon representation
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPdf ? const Color(0xFFFEE2E2) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: Center(
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: isPdf ? AppColors.danger : AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.space12),

                // Name and Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              '${document.pageCount} ${document.pageCount == 1 ? 'page' : 'pages'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            FileUtils.formatBytes(document.fileSize),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(width: 6),
                          Text(
                            AppDateUtils.formatRelative(document.updatedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite and Options
                if (onFavoriteTap != null)
                  IconButton(
                    icon: Icon(
                      document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: document.isFavorite ? AppColors.warning : AppColors.textMuted,
                      size: 22,
                    ),
                    onPressed: onFavoriteTap,
                    splashRadius: 20,
                  ),
                if (onMoreTap != null)
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onMoreTap,
                    splashRadius: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
