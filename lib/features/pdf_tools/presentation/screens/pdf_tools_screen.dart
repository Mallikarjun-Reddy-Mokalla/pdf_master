import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class PdfToolsScreen extends StatelessWidget {
  const PdfToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toolGroups = [
      _ToolGroup(
        category: 'Organize & Manage',
        items: [
          _ToolItem(
            title: 'Merge PDF',
            subtitle: 'Combine multiple PDFs into one',
            icon: Icons.call_merge_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
          _ToolItem(
            title: 'Split PDF',
            subtitle: 'Extract selected pages',
            icon: Icons.call_split_rounded,
            iconColor: AppColors.orangeBadge,
            bgColor: const Color(0xFFFFEDE0),
          ),
          _ToolItem(
            title: 'Rotate Pages',
            subtitle: 'Rotate individual pages',
            icon: Icons.rotate_right_rounded,
            iconColor: AppColors.purpleBadge,
            bgColor: const Color(0xFFF3E8FF),
          ),
          _ToolItem(
            title: 'Reorder / Delete',
            subtitle: 'Reorder or remove pages',
            icon: Icons.swap_vert_rounded,
            iconColor: AppColors.tealBadge,
            bgColor: const Color(0xFFE6FFFA),
          ),
        ],
      ),
      _ToolGroup(
        category: 'Convert & Compress',
        items: [
          _ToolItem(
            title: 'Image to PDF',
            subtitle: 'Convert JPG/PNG to PDF',
            icon: Icons.photo_library_rounded,
            iconColor: AppColors.orangeBadge,
            bgColor: const Color(0xFFFFEDE0),
          ),
          _ToolItem(
            title: 'Compress PDF',
            subtitle: 'Reduce file size efficiently',
            icon: Icons.compress_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
          _ToolItem(
            title: 'PDF to Images',
            subtitle: 'Export pages as JPG/PNG',
            icon: Icons.image_outlined,
            iconColor: AppColors.purpleBadge,
            bgColor: const Color(0xFFF3E8FF),
          ),
          _ToolItem(
            title: 'Extract Images',
            subtitle: 'Extract embedded photos',
            icon: Icons.filter_rounded,
            iconColor: AppColors.tealBadge,
            bgColor: const Color(0xFFE6FFFA),
          ),
        ],
      ),
      _ToolGroup(
        category: 'Security & Signatures',
        items: [
          _ToolItem(
            title: 'Add Signature',
            subtitle: 'Draw or import signature',
            icon: Icons.draw_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
          _ToolItem(
            title: 'Add Watermark',
            subtitle: 'Text or image watermark',
            icon: Icons.branding_watermark_rounded,
            iconColor: AppColors.orangeBadge,
            bgColor: const Color(0xFFFFEDE0),
          ),
          _ToolItem(
            title: 'Password Protect',
            subtitle: 'Encrypt PDF with password',
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.purpleBadge,
            bgColor: const Color(0xFFF3E8FF),
          ),
          _ToolItem(
            title: 'Page Numbers',
            subtitle: 'Add page numbers in headers',
            icon: Icons.format_list_numbered_rounded,
            iconColor: AppColors.tealBadge,
            bgColor: const Color(0xFFE6FFFA),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'PDF Tools',
        subtitle: 'All document operations in one place',
        showBottomDivider: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.space16),
        itemCount: toolGroups.length,
        itemBuilder: (context, groupIndex) {
          final group = toolGroups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: AppDimens.space12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                itemCount: group.items.length,
                itemBuilder: (context, itemIndex) {
                  final item = group.items[itemIndex];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item.title} ready for processing')),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: item.bgColor,
                                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                                ),
                                child: Icon(item.icon, color: item.iconColor, size: 20),
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          );
        },
      ),
    );
  }
}

class _ToolGroup {
  final String category;
  final List<_ToolItem> items;
  _ToolGroup({required this.category, required this.items});
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

