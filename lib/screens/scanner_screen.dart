import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/history_item.dart';
import '../models/barcode_definition.dart';
import '../services/history_service.dart';

class ScannerScreen extends StatefulWidget {
  final HistoryService historyService;
  final void Function(String value, String format)? onRecallToCreator;

  const ScannerScreen({
    super.key,
    required this.historyService,
    this.onRecallToCreator,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _handleScanResult(
      value: rawValue,
      rawFormat: barcode.format.name.toLowerCase(),
    );
  }

  Future<void> _scanFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isProcessing = true);
    try {
      final BarcodeCapture? capture = await _controller.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        final rawValue = barcode.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          _handleScanResult(
            value: rawValue,
            rawFormat: barcode.format.name.toLowerCase(),
          );
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No barcode or QR code detected in image.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleScanResult({required String value, required String rawFormat}) async {
    setState(() => _isProcessing = true);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Map scanner format to our internal id
    String formatId = 'qrcode';
    if (rawFormat.contains('aztec')) {
      formatId = 'azteccode';
    } else if (rawFormat.contains('matrix')) {
      formatId = 'datamatrix';
    } else if (rawFormat.contains('pdf')) {
      formatId = 'pdf417';
    } else if (rawFormat.contains('128')) {
      formatId = 'code128';
    } else if (rawFormat.contains('39')) {
      formatId = 'code39';
    } else if (rawFormat.contains('ean13')) {
      formatId = 'ean13';
    } else if (rawFormat.contains('ean8')) {
      formatId = 'ean8';
    } else if (rawFormat.contains('upca') || rawFormat.contains('upc_a')) {
      formatId = 'upca';
    } else if (rawFormat.contains('codabar')) {
      formatId = 'codabar';
    } else if (rawFormat.contains('itf')) {
      formatId = 'itf';
    }

    // Auto-save to history
    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'scanned',
      format: formatId,
      value: value,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      label: 'Scanned ${BarcodeRegistry.getById(formatId).name}',
    );
    await widget.historyService.saveItem(item);

    // Show modal bottom sheet with result
    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _buildResultSheet(ctx, item),
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildResultSheet(BuildContext context, HistoryItem item) {
    final theme = Theme.of(context);
    final def = BarcodeRegistry.getById(item.format);
    final isUrl = item.value.startsWith('http://') || item.value.startsWith('https://');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Detected ${def.category == BarcodeCategory.twoD ? '2D Matrix' : '1D Barcode'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content preview container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: SelectableText(
                item.value,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                if (isUrl)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(item.value);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('Open URL'),
                    ),
                  ),
                if (isUrl) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () {
                    Share.share(item.value);
                  },
                  icon: const Icon(Icons.share, size: 18),
                  tooltip: 'Share',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recall into creator
            if (widget.onRecallToCreator != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onRecallToCreator!(item.value, item.format);
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Open in Creator / Customize'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Toggle Flashlight',
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              _controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: 'Switch Camera',
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Scan from Gallery',
            onPressed: _scanFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Viewfinder Frame Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Instructions label
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Point camera at any 1D or 2D barcode to scan automatically',
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
