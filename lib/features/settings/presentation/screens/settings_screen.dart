import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_master/core/constants/app_colors.dart';
import 'package:pdf_master/core/constants/app_dimens.dart';
import 'package:pdf_master/core/constants/app_strings.dart';
import 'package:pdf_master/core/storage/app_storage_directory.dart';
import 'package:pdf_master/core/utils/file_utils.dart';
import 'package:pdf_master/domain/repositories/document_repository.dart';
import 'package:pdf_master/services/ad_service.dart';
import 'package:pdf_master/shared/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _storageUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    final repo = context.read<DocumentRepository>();
    final bytes = await repo.getTotalStorageUsed();
    if (mounted) setState(() => _storageUsed = bytes);
  }

  Future<void> _clearTempFiles() async {
    await AppStorageDirectory.clearTempFiles();
    await _loadStorage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Temporary cache files cleaned.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: AppStrings.navSettings,
        subtitle: 'App preferences & configuration',
        showBottomDivider: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          // Offline First Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '100% Offline Processing',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All documents are converted, edited, and stored safely on your device without cloud upload.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space20),

          // Storage & Cache
          const _SectionHeader(title: 'Storage & Cache'),
          _SettingsTile(
            icon: Icons.storage_rounded,
            title: 'Local Storage Used',
            trailing: Text(
              FileUtils.formatBytes(_storageUsed),
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          _SettingsTile(
            icon: Icons.cleaning_services_rounded,
            title: 'Clear Cache & Temp Files',
            subtitle: 'Free up temporary conversion memory',
            onTap: _clearTempFiles,
          ),
          const SizedBox(height: AppDimens.space20),

          // Document Preferences
          const _SectionHeader(title: 'Document Preferences'),
          _SettingsTile(
            icon: Icons.aspect_ratio_rounded,
            title: 'Default Page Format',
            trailing: const Text('A4 (Standard)'),
          ),
          _SettingsTile(
            icon: Icons.high_quality_rounded,
            title: 'Image Quality',
            trailing: const Text('High (90%)'),
          ),
          const SizedBox(height: AppDimens.space20),

          // Pro & Purchases
          const _SectionHeader(title: 'Premium & In-App Purchases'),
          _SettingsTile(
            icon: Icons.workspace_premium_rounded,
            title: 'PDF Master Pro',
            subtitle: 'Remove ads, unlock batch operations & OCR',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pro subscription options available')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.card_giftcard_rounded,
            title: 'Free 24h Pro Pass',
            subtitle: 'Watch a quick video ad to unlock Pro features for today',
            onTap: () {
              AdService.instance.showRewardedAd(
                onUserEarnedReward: (reward) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Congratulations! 24-hour Pro Pass unlocked!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              );
            },
          ),
          _SettingsTile(
            icon: Icons.restore_rounded,
            title: 'Restore Purchases',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchases restored successfully.')),
              );
            },
          ),
          const SizedBox(height: AppDimens.space20),

          // About & Legal
          const _SectionHeader(title: 'About & Support'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            trailing: const Text('1.0.0 (Build 1)'),
          ),
          _SettingsTile(
            icon: Icons.security_rounded,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary, size: 22),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
              : null,
          trailing: trailing ??
              (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted) : null),
          onTap: onTap,
        ),
      ),
    );
  }
}
