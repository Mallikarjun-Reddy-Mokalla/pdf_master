import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../shared/widgets/app_banner_ad.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _pageCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _shareFile() async {
    final file = File(widget.filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(widget.filePath)], text: widget.title);
    }
  }

  void _printFile() async {
    final file = File(widget.filePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: widget.title,
      );
    }
  }

  void _openInExternalApp() async {
    await OpenFilex.open(widget.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (_pageCount > 0)
              Text(
                'Page $_currentPage of $_pageCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _shareFile,
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: _printFile,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'external') {
                _openInExternalApp();
              } else if (value == 'zoom_in') {
                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
              } else if (value == 'zoom_out') {
                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'external',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Open in External App'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'zoom_in',
                child: Row(
                  children: [
                    Icon(Icons.zoom_in_rounded, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Zoom In'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'zoom_out',
                child: Row(
                  children: [
                    Icon(Icons.zoom_out_rounded, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Zoom Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(widget.filePath),
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _pageCount = details.document.pages.count;
                _isLoading = false;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.error}'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBannerAd(),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page_rounded, color: AppColors.primary),
                    tooltip: 'First Page',
                    onPressed: () => _pdfViewerController.firstPage(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_before_rounded, color: AppColors.primary),
                    tooltip: 'Previous Page',
                    onPressed: () => _pdfViewerController.previousPage(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$_currentPage / ${_pageCount > 0 ? _pageCount : 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_next_rounded, color: AppColors.primary),
                    tooltip: 'Next Page',
                    onPressed: () => _pdfViewerController.nextPage(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page_rounded, color: AppColors.primary),
                    tooltip: 'Last Page',
                    onPressed: () => _pdfViewerController.lastPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

