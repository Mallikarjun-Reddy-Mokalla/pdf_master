import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/app_storage_directory.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../domain/entities/document_entity.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../home/bloc/home_bloc.dart';
import '../../../home/bloc/home_event.dart';
import '../../../viewer/presentation/screens/pdf_viewer_screen.dart';
import '../../../../services/ad_service.dart';
import '../../../../services/file_service.dart';
import '../../../../services/pdf_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({super.key});

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  // Show a busy loading modal
  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _saveAndOpenDocument({
    required String filePath,
    required String title,
    required int pageCount,
  }) async {
    final file = File(filePath);
    final size = await file.length();
    final now = DateTime.now();

    final doc = DocumentEntity(
      name: title,
      filePath: filePath,
      fileType: 'pdf',
      fileSize: size,
      pageCount: pageCount > 0 ? pageCount : 1,
      createdAt: now,
      updatedAt: now,
    );

    final repo = context.read<DocumentRepository>();
    await repo.insertDocument(doc);

    if (!mounted) return;
    context.read<HomeBloc>().add(const LoadHomeData());

    // Show Interstitial Ad (with cooldown) before opening newly created PDF
    AdService.instance.showInterstitialAd(
      onComplete: () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => PdfViewerScreen(
              filePath: filePath,
              title: title,
            ),
          ),
        );
      },
    );
  }

  // --- 1. MERGE PDF ---
  Future<void> _mergePdf() async {
    final fileService = context.read<FileService>();
    final pdfProcessor = context.read<PdfProcessor>();

    final pickedPaths = await fileService.pickPdfFiles(allowMultiple: true);
    if (!mounted || pickedPaths.isEmpty) return;

    if (pickedPaths.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 PDF documents to merge.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final nameController = TextEditingController(
      text: 'Merged_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
    );

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge Documents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pickedPaths.length} PDF files selected to combine.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Merged Document Name',
                hintText: 'e.g. Invoices_All',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Merge PDFs'),
          ),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    final docName = nameController.text.trim().isEmpty ? 'Merged_Document' : nameController.text.trim();
    _showLoading('Merging ${pickedPaths.length} PDF files...');

    try {
      final pdfDir = await AppStorageDirectory.getPdfDirectory();
      final targetPath = p.join(pdfDir.path, '$docName.pdf');

      await pdfProcessor.mergePdfs(pickedPaths, targetPath);
      final count = await pdfProcessor.getPageCount(targetPath);

      _hideLoading();
      await _saveAndOpenDocument(filePath: targetPath, title: docName, pageCount: count);
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to merge PDFs: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // --- 2. SPLIT PDF ---
  Future<void> _splitPdf() async {
    final fileService = context.read<FileService>();
    final pdfProcessor = context.read<PdfProcessor>();

    final pickedPaths = await fileService.pickPdfFiles(allowMultiple: false);
    if (!mounted || pickedPaths.isEmpty) return;

    final sourcePath = pickedPaths.first;
    final totalPages = await pdfProcessor.getPageCount(sourcePath);

    if (totalPages <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This document only has 1 page and cannot be split.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final pagesController = TextEditingController(text: '1-$totalPages');
    final nameController = TextEditingController(
      text: '${FileUtils.getFileNameWithoutExtension(p.basename(sourcePath))}_split',
    );

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Split PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document contains $totalPages pages.',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pagesController,
              decoration: const InputDecoration(
                labelText: 'Pages to Extract',
                hintText: 'e.g. 1-2 or 1, 3, 5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Output Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Extract Pages')),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    final pageNumbers = _parsePageRange(pagesController.text, totalPages);
    if (pageNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid page range entered.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final docName = nameController.text.trim().isEmpty ? 'Split_Document' : nameController.text.trim();
    _showLoading('Extracting selected pages...');

    try {
      final pdfDir = await AppStorageDirectory.getPdfDirectory();
      final targetPath = p.join(pdfDir.path, '$docName.pdf');

      await pdfProcessor.splitPdf(sourcePath, pageNumbers, targetPath);

      _hideLoading();
      await _saveAndOpenDocument(filePath: targetPath, title: docName, pageCount: pageNumbers.length);
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to split PDF: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // --- 3. ROTATE PAGES ---
  Future<void> _rotatePdf() async {
    final fileService = context.read<FileService>();
    final pdfProcessor = context.read<PdfProcessor>();

    final pickedPaths = await fileService.pickPdfFiles(allowMultiple: false);
    if (!mounted || pickedPaths.isEmpty) return;

    final sourcePath = pickedPaths.first;
    int selectedAngle = 90;

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Rotate Pages'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select rotation angle for all pages:'),
              const SizedBox(height: 12),
              RadioListTile<int>(
                value: 90,
                groupValue: selectedAngle,
                title: const Text('90° Clockwise'),
                onChanged: (val) => setDlgState(() => selectedAngle = val!),
              ),
              RadioListTile<int>(
                value: 180,
                groupValue: selectedAngle,
                title: const Text('180° Half Turn'),
                onChanged: (val) => setDlgState(() => selectedAngle = val!),
              ),
              RadioListTile<int>(
                value: 270,
                groupValue: selectedAngle,
                title: const Text('270° Counter-Clockwise'),
                onChanged: (val) => setDlgState(() => selectedAngle = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply Rotation')),
          ],
        ),
      ),
    );

    if (proceed != true || !mounted) return;

    _showLoading('Rotating document pages...');

    try {
      final totalPages = await pdfProcessor.getPageCount(sourcePath);
      final rotations = <int, int>{
        for (int i = 1; i <= totalPages; i++) i: selectedAngle,
      };

      final pdfDir = await AppStorageDirectory.getPdfDirectory();
      final baseName = FileUtils.getFileNameWithoutExtension(p.basename(sourcePath));
      final targetPath = p.join(pdfDir.path, '${baseName}_rotated_${selectedAngle}deg.pdf');

      await pdfProcessor.rotatePdf(sourcePath, rotations, targetPath);

      _hideLoading();
      await _saveAndOpenDocument(
        filePath: targetPath,
        title: '${baseName}_rotated',
        pageCount: totalPages,
      );
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rotate PDF: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // --- 4. IMAGE TO PDF ---
  Future<void> _imageToPdf() async {
    final fileService = context.read<FileService>();
    final pdfProcessor = context.read<PdfProcessor>();

    final imagePaths = await fileService.pickImages(allowMultiple: true);
    if (!mounted || imagePaths.isEmpty) return;

    final nameController = TextEditingController(
      text: 'Photos_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
    );

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert Images to PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${imagePaths.length} photo(s) selected.',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'PDF Document Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create PDF')),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    final docName = nameController.text.trim().isEmpty ? 'Image_Document' : nameController.text.trim();
    _showLoading('Generating PDF from ${imagePaths.length} images...');

    try {
      final pdfDir = await AppStorageDirectory.getPdfDirectory();
      final targetPath = p.join(pdfDir.path, '$docName.pdf');

      await pdfProcessor.imagesToPdf(imagePaths, targetPath);

      _hideLoading();
      await _saveAndOpenDocument(
        filePath: targetPath,
        title: docName,
        pageCount: imagePaths.length,
      );
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create PDF from images: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // --- 5. COMPRESS PDF ---
  Future<void> _compressPdf() async {
    final fileService = context.read<FileService>();
    final pdfProcessor = context.read<PdfProcessor>();

    final pickedPaths = await fileService.pickPdfFiles(allowMultiple: false);
    if (!mounted || pickedPaths.isEmpty) return;

    final sourcePath = pickedPaths.first;
    final originalFile = File(sourcePath);
    final origSize = await originalFile.length();

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compress PDF Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original File Size: ${FileUtils.formatFileSize(origSize)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compressing removes redundant elements and optimizes streams for smaller size and faster sharing.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Compress Now')),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    _showLoading('Compressing PDF...');

    try {
      final pdfDir = await AppStorageDirectory.getPdfDirectory();
      final baseName = FileUtils.getFileNameWithoutExtension(p.basename(sourcePath));
      final targetPath = p.join(pdfDir.path, '${baseName}_compressed.pdf');

      await pdfProcessor.compressPdf(sourcePath, targetPath);
      final newSize = await File(targetPath).length();
      final totalPages = await pdfProcessor.getPageCount(targetPath);

      _hideLoading();

      final saved = ((origSize - newSize) / origSize * 100).clamp(0, 100).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compressed! Saved $saved% (${FileUtils.formatFileSize(origSize)} → ${FileUtils.formatFileSize(newSize)})',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      await _saveAndOpenDocument(
        filePath: targetPath,
        title: '${baseName}_compressed',
        pageCount: totalPages,
      );
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to compress PDF: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // --- 6. ADD WATERMARK ---
  Future<void> _addWatermark() async {
    final fileService = context.read<FileService>();
    final pdfProcessor = context.read<PdfProcessor>();

    final pickedPaths = await fileService.pickPdfFiles(allowMultiple: false);
    if (!mounted || pickedPaths.isEmpty) return;

    final sourcePath = pickedPaths.first;
    final watermarkController = TextEditingController(text: 'CONFIDENTIAL');

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Watermark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A diagonal semi-transparent watermark will be added to every page.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: watermarkController,
              decoration: const InputDecoration(
                labelText: 'Watermark Text',
                hintText: 'e.g. DRAFT, CONFIDENTIAL, OFFICIAL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply Watermark')),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    final watermarkText = watermarkController.text.trim().isEmpty
        ? 'CONFIDENTIAL'
        : watermarkController.text.trim();

    _showLoading('Applying watermark to all pages...');

    try {
      final pdfDir = await AppStorageDirectory.getPdfDirectory();
      final baseName = FileUtils.getFileNameWithoutExtension(p.basename(sourcePath));
      final targetPath = p.join(pdfDir.path, '${baseName}_watermarked.pdf');

      await pdfProcessor.addWatermark(sourcePath, watermarkText, targetPath);
      final count = await pdfProcessor.getPageCount(targetPath);

      _hideLoading();
      await _saveAndOpenDocument(
        filePath: targetPath,
        title: '${baseName}_watermarked',
        pageCount: count,
      );
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add watermark: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  // --- 7. PASSWORD PROTECT ---
  Future<void> _protectPdf() async {
    final fileService = context.read<FileService>();
    final pdfProcessor = context.read<PdfProcessor>();

    final pickedPaths = await fileService.pickPdfFiles(allowMultiple: false);
    if (!mounted || pickedPaths.isEmpty) return;

    final sourcePath = pickedPaths.first;
    final passwordController = TextEditingController();
    bool obscure = true;

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Password Protect PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set a password to encrypt this document with AES-256 bit encryption.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Enter Password',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDlgState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Encrypt Document')),
          ],
        ),
      ),
    );

    if (proceed != true || !mounted) return;

    final password = passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password cannot be empty.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    _showLoading('Encrypting document...');

    try {
      final pdfDir = await AppStorageDirectory.getPdfDirectory();
      final baseName = FileUtils.getFileNameWithoutExtension(p.basename(sourcePath));
      final targetPath = p.join(pdfDir.path, '${baseName}_protected.pdf');

      await pdfProcessor.protectPdf(sourcePath, password, targetPath);
      final count = await pdfProcessor.getPageCount(sourcePath);

      _hideLoading();
      await _saveAndOpenDocument(
        filePath: targetPath,
        title: '${baseName}_protected',
        pageCount: count,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document encrypted and password-protected successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to protect PDF: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  List<int> _parsePageRange(String input, int maxPages) {
    final result = <int>{};
    final parts = input.split(RegExp(r'[,;]'));
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final sub = trimmed.split('-');
        if (sub.length == 2) {
          final start = int.tryParse(sub[0].trim());
          final end = int.tryParse(sub[1].trim());
          if (start != null && end != null) {
            final from = start.clamp(1, maxPages);
            final to = end.clamp(1, maxPages);
            for (int i = from; i <= to; i++) {
              result.add(i);
            }
          }
        }
      } else {
        final single = int.tryParse(trimmed);
        if (single != null && single >= 1 && single <= maxPages) {
          result.add(single);
        }
      }
    }
    final sorted = result.toList()..sort();
    return sorted;
  }

  void _onToolSelected(String title) {
    switch (title) {
      case 'Merge PDF':
        _mergePdf();
        break;
      case 'Split PDF':
      case 'Reorder / Delete':
        _splitPdf();
        break;
      case 'Rotate Pages':
        _rotatePdf();
        break;
      case 'Image to PDF':
        _imageToPdf();
        break;
      case 'Compress PDF':
        _compressPdf();
        break;
      case 'Add Watermark':
        _addWatermark();
        break;
      case 'Password Protect':
        _protectPdf();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title tool is being prepared.')),
        );
    }
  }

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
            subtitle: 'Extract or reorder pages',
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
        ],
      ),
      _ToolGroup(
        category: 'Security & Branding',
        items: [
          _ToolItem(
            title: 'Add Watermark',
            subtitle: 'Diagonal text watermark',
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
                  return Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _onToolSelected(item.title),
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
