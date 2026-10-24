import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/barcode_definition.dart';

class BarcodePreviewWidget extends StatelessWidget {
  final String formatId;
  final String data;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool showText;
  final String? customLabel;
  final bool quietZone;
  final double barHeight;
  final double width;
  final double height;
  final bool showLogoInQrCenter;
  final String? logoUrl;
  final String? logoFilePath;
  final int qrErrorCorrectionLevel; // QrErrorCorrectLevel

  const BarcodePreviewWidget({
    super.key,
    required this.formatId,
    required this.data,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.showText = true,
    this.customLabel,
    this.quietZone = true,
    this.barHeight = 60,
    this.width = 240,
    this.height = 240,
    this.showLogoInQrCenter = false,
    this.logoUrl,
    this.logoFilePath,
    this.qrErrorCorrectionLevel = QrErrorCorrectLevel.M,
  });

  @override
  Widget build(BuildContext context) {
    final cleanData = data.trim();
    if (cleanData.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: backgroundColor,
        alignment: Alignment.center,
        child: Text(
          'Enter text to generate code',
          style: TextStyle(color: foregroundColor.withOpacity(0.5), fontSize: 13),
        ),
      );
    }

    final definition = BarcodeRegistry.getById(formatId);

    // If QR Code and embedded center logo is requested
    if (formatId == 'qrcode' && showLogoInQrCenter && (logoUrl != null || logoFilePath != null)) {
      ImageProvider? logoProvider;
      if (logoFilePath != null && logoFilePath!.isNotEmpty) {
        logoProvider = FileImage(File(logoFilePath!));
      } else if (logoUrl != null && logoUrl!.isNotEmpty) {
        logoProvider = NetworkImage(logoUrl!);
      }

      return Container(
        color: backgroundColor,
        padding: EdgeInsets.all(quietZone ? 12 : 0),
        child: QrImageView(
          data: cleanData,
          version: QrVersions.auto,
          size: width,
          errorCorrectionLevel: qrErrorCorrectionLevel,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: foregroundColor,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: foregroundColor,
          ),
          embeddedImage: logoProvider,
          embeddedImageStyle: const QrEmbeddedImageStyle(
            size: Size(44, 44),
          ),
          errorStateBuilder: (c, err) {
            return Center(
              child: Text(
                'Invalid QR Data',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            );
          },
        ),
      );
    }

    // Standard barcode rendering using BarcodeWidget (pure Dart, high quality SVG & canvas)
    try {
      final barcode = definition.barcodeFactory();
      final is2D = definition.category == BarcodeCategory.twoD;

      return Container(
        color: backgroundColor,
        padding: EdgeInsets.all(quietZone ? 12 : 0),
        child: BarcodeWidget(
          barcode: barcode,
          data: cleanData,
          width: is2D ? width : width * 1.2,
          height: is2D ? height : barHeight + (showText ? 24 : 0),
          color: foregroundColor,
          backgroundColor: backgroundColor,
          drawText: showText && !is2D,
          altText: customLabel?.isNotEmpty == true ? customLabel : null,
          errorBuilder: (context, error) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    'Format Mismatch for ${definition.name}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expected syntax: ${definition.placeholder}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Text(
          'Error generating barcode: $e',
          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}
