import 'dart:io';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

abstract class PdfProcessor {
  Future<String> imagesToPdf(List<String> imagePaths, String outputPath);
  Future<String> mergePdfs(List<String> pdfPaths, String outputPath);
  Future<String> splitPdf(String inputPath, List<int> pageNumbers, String outputPath);
  Future<String> compressPdf(String inputPath, String outputPath);
  Future<String> rotatePdf(String inputPath, Map<int, int> rotations, String outputPath);
  Future<String> addWatermark(String inputPath, String watermarkText, String outputPath);
  Future<String> protectPdf(String inputPath, String password, String outputPath);
  Future<int> getPageCount(String inputPath);
}

class SyncfusionPdfProcessor implements PdfProcessor {
  @override
  Future<int> getPageCount(String inputPath) async {
    final file = File(inputPath);
    if (!await file.exists()) return 0;
    final bytes = await file.readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final count = doc.pages.count;
    doc.dispose();
    return count;
  }

  @override
  Future<String> imagesToPdf(List<String> imagePaths, String outputPath) async {
    final PdfDocument document = PdfDocument();
    try {
      for (final imagePath in imagePaths) {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) continue;
        final imageBytes = await imageFile.readAsBytes();
        final PdfBitmap bitmap = PdfBitmap(imageBytes);

        // Add page matching image aspect ratio or standard A4
        final PdfPage page = document.pages.add();
        final pageSize = page.getClientSize();

        // Fit image within page bounds while maintaining aspect ratio
        final double imgWidth = bitmap.width.toDouble();
        final double imgHeight = bitmap.height.toDouble();
        final double scale = (pageSize.width / imgWidth < pageSize.height / imgHeight)
            ? pageSize.width / imgWidth
            : pageSize.height / imgHeight;

        final double destWidth = imgWidth * scale;
        final double destHeight = imgHeight * scale;
        final double destX = (pageSize.width - destWidth) / 2;
        final double destY = (pageSize.height - destHeight) / 2;

        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(destX, destY, destWidth, destHeight),
        );
      }

      final List<int> bytes = await document.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(bytes, flush: true);
      return outputPath;
    } finally {
      document.dispose();
    }
  }

  @override
  Future<String> mergePdfs(List<String> pdfPaths, String outputPath) async {
    final PdfDocument finalDocument = PdfDocument();
    try {
      for (final path in pdfPaths) {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final PdfDocument sourceDoc = PdfDocument(inputBytes: bytes);
        for (int i = 0; i < sourceDoc.pages.count; i++) {
          final PdfTemplate template = sourceDoc.pages[i].createTemplate();
          final PdfPage newPage = finalDocument.pages.add();
          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            newPage.getClientSize(),
          );
        }
        sourceDoc.dispose();
      }

      final List<int> outputBytes = await finalDocument.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputPath;
    } finally {
      finalDocument.dispose();
    }
  }

  @override
  Future<String> splitPdf(String inputPath, List<int> pageNumbers, String outputPath) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();
    final PdfDocument sourceDoc = PdfDocument(inputBytes: bytes);
    final PdfDocument splitDoc = PdfDocument();

    try {
      for (final pageNumber in pageNumbers) {
        final zeroIndexed = pageNumber - 1;
        if (zeroIndexed >= 0 && zeroIndexed < sourceDoc.pages.count) {
          final template = sourceDoc.pages[zeroIndexed].createTemplate();
          final newPage = splitDoc.pages.add();
          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            newPage.getClientSize(),
          );
        }
      }

      final List<int> outputBytes = await splitDoc.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputPath;
    } finally {
      sourceDoc.dispose();
      splitDoc.dispose();
    }
  }

  @override
  Future<String> compressPdf(String inputPath, String outputPath) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    try {
      document.compressionLevel = PdfCompressionLevel.best;
      final List<int> outputBytes = await document.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputPath;
    } finally {
      document.dispose();
    }
  }

  @override
  Future<String> rotatePdf(String inputPath, Map<int, int> rotations, String outputPath) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    try {
      rotations.forEach((pageNumber, angle) {
        final zeroIndexed = pageNumber - 1;
        if (zeroIndexed >= 0 && zeroIndexed < document.pages.count) {
          final page = document.pages[zeroIndexed];
          switch (angle % 360) {
            case 90:
              page.rotation = PdfPageRotateAngle.rotateAngle90;
              break;
            case 180:
              page.rotation = PdfPageRotateAngle.rotateAngle180;
              break;
            case 270:
              page.rotation = PdfPageRotateAngle.rotateAngle270;
              break;
            default:
              page.rotation = PdfPageRotateAngle.rotateAngle0;
          }
        }
      });

      final List<int> outputBytes = await document.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputPath;
    } finally {
      document.dispose();
    }
  }

  @override
  Future<String> addWatermark(String inputPath, String watermarkText, String outputPath) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    try {
      final font = PdfStandardFont(PdfFontFamily.helvetica, 36, style: PdfFontStyle.bold);
      final brush = PdfSolidBrush(PdfColor(180, 180, 180, 80));
      final pen = PdfPen(PdfColor(180, 180, 180, 80), width: 1);

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final Size size = page.getClientSize();
        final Size textSize = font.measureString(watermarkText);

        final PdfGraphicsState state = page.graphics.save();
        page.graphics.translateTransform(size.width / 2, size.height / 2);
        page.graphics.rotateTransform(-45);
        page.graphics.drawString(
          watermarkText,
          font,
          brush: brush,
          pen: pen,
          bounds: Rect.fromLTWH(
            -textSize.width / 2,
            -textSize.height / 2,
            textSize.width,
            textSize.height,
          ),
        );
        page.graphics.restore(state);
      }

      final List<int> outputBytes = await document.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputPath;
    } finally {
      document.dispose();
    }
  }

  @override
  Future<String> protectPdf(String inputPath, String password, String outputPath) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    try {
      final PdfSecurity security = document.security;
      security.userPassword = password;
      security.ownerPassword = password;
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;

      final List<int> outputBytes = await document.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputPath;
    } finally {
      document.dispose();
    }
  }
}
