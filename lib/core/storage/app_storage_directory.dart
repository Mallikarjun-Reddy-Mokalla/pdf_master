import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppStorageDirectory {
  AppStorageDirectory._();

  static Directory? _baseDirectory;

  /// Root app-private document directory
  static Future<Directory> getBaseDirectory() async {
    if (_baseDirectory != null) return _baseDirectory!;
    final appDocDir = await getApplicationDocumentsDirectory();
    final pdfMasterDir = Directory(p.join(appDocDir.path, 'PDFMaster'));
    if (!await pdfMasterDir.exists()) {
      await pdfMasterDir.create(recursive: true);
    }
    _baseDirectory = pdfMasterDir;
    return _baseDirectory!;
  }

  /// Folder for general PDFs
  static Future<Directory> getPdfDirectory() async {
    return _getOrCreateSubdir(['documents', 'pdf']);
  }

  /// Folder for scanned documents
  static Future<Directory> getScannedDirectory() async {
    return _getOrCreateSubdir(['documents', 'scanned']);
  }

  /// Folder for converted files (e.g. image-to-PDF)
  static Future<Directory> getConvertedDirectory() async {
    return _getOrCreateSubdir(['documents', 'converted']);
  }

  /// Folder for edited documents (merged, split, rotated, watermarked)
  static Future<Directory> getEditedDirectory() async {
    return _getOrCreateSubdir(['documents', 'edited']);
  }

  /// Folder for thumbnails
  static Future<Directory> getThumbnailDirectory() async {
    return _getOrCreateSubdir(['thumbnails']);
  }

  /// Temporary processing directory
  static Future<Directory> getTempDirectory() async {
    return _getOrCreateSubdir(['temp']);
  }

  /// Database directory
  static Future<Directory> getDatabaseDirectory() async {
    return _getOrCreateSubdir(['database']);
  }

  /// Helper to create nested directory
  static Future<Directory> _getOrCreateSubdir(List<String> pathSegments) async {
    final base = await getBaseDirectory();
    final fullPath = p.joinAll([base.path, ...pathSegments]);
    final dir = Directory(fullPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Clear intermediate temp files
  static Future<void> clearTempFiles() async {
    try {
      final tempDir = await getTempDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (_) {
      // Ignore cleanup failures
    }
  }

  /// Calculate total storage size consumed by PDFMaster directory in bytes
  static Future<int> calculateTotalStorageUsed() async {
    try {
      final base = await getBaseDirectory();
      if (!await base.exists()) return 0;
      int total = 0;
      await for (final entity in base.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}

