import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../domain/entities/document_entity.dart';

class DocumentActionsModal extends StatelessWidget {
  final DocumentEntity document;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onPrint;
  final VoidCallback onRename;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const DocumentActionsModal({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onShare,
    required this.onPrint,
    required this.onRename,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required DocumentEntity document,
    required VoidCallback onOpen,
    required VoidCallback onShare,
    required VoidCallback onPrint,
    required VoidCallback onRename,
    required VoidCallback onToggleFavorite,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => DocumentActionsModal(
        document: document,
        onOpen: onOpen,
        onShare: onShare,
        onPrint: onPrint,
        onRename: onRename,
        onToggleFavorite: onToggleFavorite,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${document.pageCount} pages • ${document.fileType.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),
            const Divider(color: AppColors.divider),

            // Actions
            _ActionItem(
              icon: Icons.visibility_outlined,
              title: 'Open Document',
              onTap: () {
                Navigator.pop(context);
                onOpen();
              },
            ),
            _ActionItem(
              icon: Icons.share_outlined,
              title: 'Share Document',
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            _ActionItem(
              icon: Icons.print_outlined,
              title: 'Print',
              onTap: () {
                Navigator.pop(context);
                onPrint();
              },
            ),
            _ActionItem(
              icon: Icons.drive_file_rename_outline_rounded,
              title: 'Rename',
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            _ActionItem(
              icon: document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              title: document.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              iconColor: document.isFavorite ? AppColors.warning : null,
              onTap: () {
                Navigator.pop(context);
                onToggleFavorite();
              },
            ),
            const Divider(color: AppColors.divider),
            _ActionItem(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Document',
              textColor: AppColors.danger,
              iconColor: AppColors.danger,
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}

