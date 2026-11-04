import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../core/storage/app_storage_directory.dart';
import '../core/utils/file_utils.dart';
import '../domain/entities/document_entity.dart';
import '../domain/repositories/document_repository.dart';

class FileService {
  final ImagePicker _imagePicker;
  final DocumentRepository repository;

  FileService({
    ImagePicker? imagePicker,
    required this.repository,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  /// Pick one or multiple PDF files from device
  Future<List<String>> pickPdfFiles({bool allowMultiple = false}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: allowMultiple,
    );

    if (result != null && result.paths.isNotEmpty) {
      return result.paths.whereType<String>().toList();
    }
    return [];
  }

  /// Pick images from gallery
  Future<List<String>> pickImages({bool allowMultiple = true}) async {
    if (allowMultiple) {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      return images.map((x) => x.path).toList();
    } else {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      return image != null ? [image.path] : [];
    }
  }

  /// Open document using default device application
  Future<OpenResult> openPdfFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }

  /// Share file via system share sheet
  Future<ShareResult> sharePdfFile(String filePath, {String? text}) async {
    return await Share.shareXFiles(
      [XFile(filePath)],
      text: text,
    );
  }

  /// Print document via AirPrint / Android Print Service
  Future<bool> printPdfFile(String filePath, String title) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final bytes = await file.readAsBytes();
    return await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: title,
    );
  }

  /// Import an external PDF into the app's managed storage & database
  Future<DocumentEntity?> importPdfToApp(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;

    final targetDir = await AppStorageDirectory.getPdfDirectory();
    final originalName = p.basename(sourcePath);
    final targetPath = p.join(targetDir.path, originalName);

    // Copy to app storage
    final copiedFile = await sourceFile.copy(targetPath);
    final fileSize = await copiedFile.length();

    // Inspect page count via Syncfusion
    int pageCount = 1;
    try {
      final bytes = await copiedFile.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      pageCount = doc.pages.count;
      doc.dispose();
    } catch (_) {
      pageCount = 1;
    }

    final now = DateTime.now();
    final newDoc = DocumentEntity(
      name: FileUtils.getFileNameWithoutExtension(originalName),
      filePath: copiedFile.path,
      fileType: 'pdf',
      fileSize: fileSize,
      pageCount: pageCount,
      createdAt: now,
      updatedAt: now,
    );

    final savedDoc = await repository.insertDocument(newDoc);
    await repository.recordRecentFile(savedDoc.id!);
    return savedDoc;
  }
}
