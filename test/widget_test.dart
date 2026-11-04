import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_master/core/constants/app_strings.dart';
import 'package:pdf_master/core/utils/file_utils.dart';

void main() {
  group('FileUtils Unit Tests', () {
    test('formatBytes formats zero and bytes correctly', () {
      expect(FileUtils.formatBytes(0), '0 B');
      expect(FileUtils.formatBytes(1024), '1.0 KB');
      expect(FileUtils.formatBytes(1048576), '1.0 MB');
    });

    test('getFileNameWithoutExtension returns clean name', () {
      expect(FileUtils.getFileNameWithoutExtension('document.pdf'), 'document');
      expect(FileUtils.getFileNameWithoutExtension('/path/to/invoice.scan.pdf'), 'invoice.scan');
    });

    test('getFileExtension returns extension', () {
      expect(FileUtils.getFileExtension('test.pdf'), 'pdf');
      expect(FileUtils.getFileExtension('photo.PNG'), 'png');
    });
  });

  group('AppStrings Sanity Test', () {
    test('Check app name and tagline', () {
      expect(AppStrings.appName, 'PDF Master');
      expect(AppStrings.tagline, 'All Your Documents. One Powerful App.');
    });
  });
}
