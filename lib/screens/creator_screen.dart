import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:barcode/barcode.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/barcode_definition.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../widgets/barcode_preview_widget.dart';
import '../widgets/content_type_dialog.dart';

class CreatorScreen extends StatefulWidget {
  final HistoryService historyService;
  final String? initialValue;
  final String? initialFormat;
  final void Function(String value, String format)? onOpenCardBuilder;

  const CreatorScreen({
    super.key,
    required this.historyService,
    this.initialValue,
    this.initialFormat,
    this.onOpenCardBuilder,
  });

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _previewKey = GlobalKey();

  late String _selectedFormatId;
  Color _foregroundColor = Colors.black;
  Color _backgroundColor = Colors.white;
  bool _quietZone = true;
  bool _showText = true;
  String _customLabel = '';
  double _barHeight = 60.0;
  int _qrEcLevel = QrErrorCorrectLevel.M;

  // Center logo options for QR
  bool _showLogoInCenter = false;
  String? _logoFilePath;
  String? _logoUrl;

  bool _isAdvancedExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedFormatId = widget.initialFormat ?? 'qrcode';
    _textController.text = widget.initialValue ?? 'https://qragga.hivepen.com';
    _textController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant CreatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null && widget.initialValue != oldWidget.initialValue) {
      _textController.text = widget.initialValue!;
    }
    if (widget.initialFormat != null && widget.initialFormat != oldWidget.initialFormat) {
      _selectedFormatId = widget.initialFormat!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickCenterLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoFilePath = image.path;
        _showLogoInCenter = true;
      });
    }
  }

  Future<void> _saveToHistory() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'created',
      format: _selectedFormatId,
      value: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      label: 'Created ${_getFormatName(_selectedFormatId)}',
      personalization: PersonalizationOptions(
        fgColor: _colorToHex(_foregroundColor),
        bgColor: _colorToHex(_backgroundColor),
        includeText: _showText,
        customLabel: _customLabel.isNotEmpty ? _customLabel : null,
        quietZone: _quietZone,
        barHeight: _barHeight,
      ),
    );

    await widget.historyService.saveItem(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to offline history!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getFormatName(String id) {
    return BarcodeRegistry.getById(id).name;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Future<void> _shareBarcode() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Barcode generated with QRagga: ${_textController.text}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing failed: $e')),
        );
      }
    }
  }

  Future<void> _exportSvg() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      final def = BarcodeRegistry.getById(_selectedFormatId);
      final barcode = def.barcodeFactory();
      final svgString = barcode.toSvg(
        text,
        width: 300,
        height: def.category == BarcodeCategory.twoD ? 300 : 100,
        color: _foregroundColor.value,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qragga_${_selectedFormatId}_${DateTime.now().millisecondsSinceEpoch}.svg');
      await file.writeAsString(svgString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Vector Barcode (SVG) from QRagga',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export SVG: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDef = BarcodeRegistry.getById(_selectedFormatId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Creator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Barcode',
            onPressed: _shareBarcode,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save to History',
            onPressed: _saveToHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barcode Format Selector Chips
            _buildFormatSelector(theme),
            const SizedBox(height: 16),

            // Content Input Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Content to Encode',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final generated = await ContentTypeDialogHelper.showQuickContentPicker(context);
                            if (generated != null) {
                              setState(() {
                                _textController.text = generated;
                              });
                            }
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Quick Presets'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: currentDef.placeholder,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentDef.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Interactive Preview Box
            Center(
              child: RepaintBoundary(
                key: _previewKey,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 260, minHeight: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: BarcodePreviewWidget(
                    formatId: _selectedFormatId,
                    data: _textController.text,
                    foregroundColor: _foregroundColor,
                    backgroundColor: _backgroundColor,
                    showText: _showText,
                    customLabel: _customLabel,
                    quietZone: _quietZone,
                    barHeight: _barHeight,
                    width: 220,
                    height: 220,
                    showLogoInQrCenter: _showLogoInCenter,
                    logoFilePath: _logoFilePath,
                    logoUrl: _logoUrl,
                    qrErrorCorrectionLevel: _qrEcLevel,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Row: Copy, Export SVG, Certificate Card Builder
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _textController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Content copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Text'),
                ),
                OutlinedButton.icon(
                  onPressed: _exportSvg,
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Export SVG'),
                ),
                if (widget.onOpenCardBuilder != null)
                  FilledButton.icon(
                    onPressed: () {
                      widget.onOpenCardBuilder!(
                        _textController.text,
                        _selectedFormatId,
                      );
                    },
                    icon: const Icon(Icons.style, size: 16),
                    label: const Text('Open in Card Builder'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Customization Options Panel (Expandable)
            ExpansionTile(
              initiallyExpanded: _isAdvancedExpanded,
              onExpansionChanged: (val) => setState(() => _isAdvancedExpanded = val),
              leading: const Icon(Icons.tune),
              title: const Text('Styling & Barcode Settings'),
              subtitle: const Text('Colors, error correction, margins & logo'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: [
                      // Color Pickers
                      Row(
                        children: [
                          Expanded(
                            child: _buildColorTile(
                              label: 'Barcode Color',
                              color: _foregroundColor,
                              onSelect: (c) => setState(() => _foregroundColor = c),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildColorTile(
                              label: 'Background',
                              color: _backgroundColor,
                              onSelect: (c) => setState(() => _backgroundColor = c),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quiet Zone Toggle
                      SwitchListTile(
                        title: const Text('Quiet Zone (Margin)'),
                        subtitle: const Text('Leave safety padding around the code'),
                        value: _quietZone,
                        onChanged: (val) => setState(() => _quietZone = val),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // If 1D Barcode: Show text & Bar Height
                      if (currentDef.category == BarcodeCategory.oneD) ...[
                        SwitchListTile(
                          title: const Text('Include Text Underneath'),
                          value: _showText,
                          onChanged: (val) => setState(() => _showText = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Bar Height: '),
                            Expanded(
                              child: Slider(
                                value: _barHeight,
                                min: 30.0,
                                max: 120.0,
                                onChanged: (val) => setState(() => _barHeight = val),
                              ),
                            ),
                            Text('${_barHeight.round()} px'),
                          ],
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Custom Label (replaces code text)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _customLabel = val),
                        ),
                      ],

                      // If QR Code: Error Correction & Center Logo
                      if (_selectedFormatId == 'qrcode') ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Text('QR Error Correction: '),
                            const Spacer(),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: QrErrorCorrectLevel.L, label: Text('L (7%)')),
                                ButtonSegment(value: QrErrorCorrectLevel.M, label: Text('M (15%)')),
                                ButtonSegment(value: QrErrorCorrectLevel.Q, label: Text('Q (25%)')),
                                ButtonSegment(value: QrErrorCorrectLevel.H, label: Text('H (30%)')),
                              ],
                              selected: {_qrEcLevel},
                              onSelectionChanged: (set) {
                                setState(() => _qrEcLevel = set.first);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Embed Logo in Center'),
                          subtitle: const Text('Place custom avatar or brand icon in the QR center'),
                          value: _showLogoInCenter,
                          onChanged: (val) => setState(() => _showLogoInCenter = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_showLogoInCenter)
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickCenterLogo,
                                icon: const Icon(Icons.image, size: 16),
                                label: const Text('Pick Image from Gallery'),
                              ),
                              if (_logoFilePath != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  'Image Selected',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barcode Format',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: BarcodeRegistry.definitions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final def = BarcodeRegistry.definitions[index];
              final isSelected = def.id == _selectedFormatId;
              final is2D = def.category == BarcodeCategory.twoD;

              return ChoiceChip(
                label: Text(def.name),
                avatar: Icon(
                  is2D ? Icons.qr_code_2 : Icons.barcode_reader,
                  size: 16,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFormatId = def.id;
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorTile({
    required String label,
    required Color color,
    required ValueChanged<Color> onSelect,
  }) {
    return InkWell(
      onTap: () => _showColorPickerDialog(label, color, onSelect),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(String label, Color currentColor, ValueChanged<Color> onSelect) {
    final colors = [
      Colors.black,
      Colors.white,
      const Color(0xFF6750A4), // Deep Purple
      const Color(0xFF006A6A), // Teal
      const Color(0xFF0061A4), // Blue
      const Color(0xFF386A20), // Green
      const Color(0xFF984061), // Berry
      const Color(0xFFD32F2F), // Red
      const Color(0xFFF57C00), // Orange
      const Color(0xFF1E293B), // Navy Slate
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((c) {
            return InkWell(
              onTap: () {
                onSelect(c);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 2),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
