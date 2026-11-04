import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_master/core/constants/app_colors.dart';
import 'package:pdf_master/core/storage/app_storage_directory.dart';
import 'package:pdf_master/domain/entities/document_entity.dart';
import 'package:pdf_master/domain/repositories/document_repository.dart';
import 'package:pdf_master/features/home/bloc/home_bloc.dart';
import 'package:pdf_master/features/home/bloc/home_event.dart';
import 'package:pdf_master/services/file_service.dart';
import 'package:pdf_master/services/pdf_service.dart';

class ScannerScreen extends StatefulWidget {
  final VoidCallback onScanComplete;

  const ScannerScreen({super.key, required this.onScanComplete});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  final List<String> _scannedImagePaths = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _capturePage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _scannedImagePaths.add(photo.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final fileService = context.read<FileService>();
    final paths = await fileService.pickImages(allowMultiple: true);
    if (paths.isNotEmpty && mounted) {
      setState(() {
        _scannedImagePaths.addAll(paths);
      });
    }
  }

  Future<void> _finishAndSavePdf() async {
    if (_scannedImagePaths.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final pdfProcessor = context.read<PdfProcessor>();
      final repo = context.read<DocumentRepository>();
      final scannedDir = await AppStorageDirectory.getScannedDirectory();

      final docName = 'Scan_${DateTime.now().millisecondsSinceEpoch}';
      final outputPath = p.join(scannedDir.path, '$docName.pdf');

      await pdfProcessor.imagesToPdf(_scannedImagePaths, outputPath);

      final outputFile = File(outputPath);
      final fileSize = await outputFile.length();
      final now = DateTime.now();

      final doc = DocumentEntity(
        name: docName,
        filePath: outputPath,
        fileType: 'pdf',
        fileSize: fileSize,
        pageCount: _scannedImagePaths.length,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await repo.insertDocument(doc);
      await repo.recordRecentFile(saved.id!);

      if (mounted) {
        context.read<HomeBloc>().add(const LoadHomeData());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanned document saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onScanComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview or Fallback Placeholder
            if (_isCameraInitialized && _cameraController != null)
              Center(child: CameraPreview(_cameraController!))
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera Scanner Ready',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can capture camera feeds or import photos directly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Pick Photos to Scan'),
                    ),
                  ],
                ),
              ),

            // Top overlay bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onScanComplete,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_scannedImagePaths.length} pages captured',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_scannedImagePaths.isNotEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(70, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: _isProcessing ? null : _finishAndSavePdf,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save PDF'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Bottom camera shutter controls
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery import
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                        onPressed: _pickFromGallery,
                      ),
                      // Shutter button
                      GestureDetector(
                        onTap: _capturePage,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Clear captured pages
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                        onPressed: _scannedImagePaths.isNotEmpty
                            ? () => setState(() => _scannedImagePaths.clear())
                            : null,
                      ),
                    ],
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
