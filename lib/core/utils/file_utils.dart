import 'dart:math';

class FileUtils {
  FileUtils._();

  /// Formats byte count to human-readable string (e.g. 1.2 MB, 340 KB)
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, clampedIndex);
    return '${size.toStringAsFixed(decimals)} ${suffixes[clampedIndex]}';
  }

  /// Alias for formatBytes
  static String formatFileSize(int bytes, [int decimals = 1]) => formatBytes(bytes, decimals);

  /// Extracts file extension from file path or file name
  static String getFileExtension(String filePath) {
    if (!filePath.contains('.')) return '';
    return filePath.split('.').last.toLowerCase();
  }

  /// Extracts file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    if (!fileName.contains('.')) return fileName;
    final lastDotIndex = fileName.lastIndexOf('.');
    return fileName.substring(0, lastDotIndex);
  }

  /// Sanitize file name by replacing prohibited characters
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}

