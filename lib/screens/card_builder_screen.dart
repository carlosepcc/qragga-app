import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_item.dart';
import '../models/card_template.dart';
import '../models/barcode_definition.dart';
import '../services/history_service.dart';
import '../widgets/barcode_preview_widget.dart';

class CardBuilderScreen extends StatefulWidget {
  final HistoryService historyService;
  final String initialValue;
  final String initialFormat;

  const CardBuilderScreen({
    super.key,
    required this.historyService,
    this.initialValue = 'https://qragga.hivepen.com',
    this.initialFormat = 'qrcode',
  });

  @override
  State<CardBuilderScreen> createState() => _CardBuilderScreenState();
}

class _CardBuilderScreenState extends State<CardBuilderScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _footerController;
  late TextEditingController _valueController;

  late String _format;
  String _bgType = 'gradient'; // solid, gradient, minimal
  Color _solidColor = const Color(0xFF6750A4);
  Color _gradientStart = const Color(0xFF6750A4);
  Color _gradientEnd = const Color(0xFFE8DEF8);
  Color _textColor = Colors.white;
  String _borderRadius = 'large'; // none, medium, large, extra-large
  String _borderStyle = 'none'; // none, thin, dashed
  bool _showShadow = true;
  bool _showValue = false;
  bool _showLogo = true;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    _valueController = TextEditingController(text: widget.initialValue);
    _titleController = TextEditingController(text: 'QRagga Certificate');
    _bodyController = TextEditingController(text: 'Scan this code to verify information');
    _footerController = TextEditingController(text: 'Verified Offline • QRagga');

    _autoFillFromUrl(widget.initialValue);

    _valueController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
    _footerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _footerController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _autoFillFromUrl(String url) {
    final clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) return;

    try {
      final uri = Uri.parse(clean);
      final host = uri.host.toLowerCase().replaceAll('www.', '');
      if (host.contains('github.com')) {
        _titleController.text = 'GitHub Repository';
        _bodyController.text = 'Open-source code, developers & secure repositories';
        _footerController.text = 'Verified Open-Source • GitHub';
      } else if (host.contains('youtube.com') || host.contains('youtu.be')) {
        _titleController.text = 'YouTube Video';
        _bodyController.text = 'Stream high-definition videos, channels & podcasts';
        _footerController.text = 'Official Broadcast • YouTube';
      } else if (host.contains('linkedin.com')) {
        _titleController.text = 'LinkedIn Profile';
        _bodyController.text = 'Professional networking, resumes & career contacts';
        _footerController.text = 'Verified Professional • LinkedIn';
      } else if (host.contains('spotify.com')) {
        _titleController.text = 'Spotify Playlist';
        _bodyController.text = 'High-fidelity audio stream, podcast or album';
        _footerController.text = 'Official Audio Link • Spotify';
      } else if (host.isNotEmpty) {
        final name = host.split('.').first;
        final capitalized = name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : 'Web';
        _titleController.text = '$capitalized Portal';
        _bodyController.text = 'Direct verified link to $host';
        _footerController.text = 'Secure Link • $capitalized';
      }
    } catch (_) {}
  }

  void _applyTemplate(CardTemplate template) {
    setState(() {
      _titleController.text = template.options.title;
      _bodyController.text = template.options.body;
      _footerController.text = template.options.footer;
      _bgType = template.options.bgType;
      _solidColor = _hexToColor(template.options.bgColor);
      _gradientStart = _hexToColor(template.options.gradientStart);
      _gradientEnd = _hexToColor(template.options.gradientEnd);
      _textColor = _hexToColor(template.options.textColor);
      _borderRadius = template.options.borderRadius;
      _borderStyle = template.options.borderStyle;
      _showShadow = template.options.showShadow;
      _showLogo = template.options.showLogo;
      _showValue = template.options.showValue;
    });
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Future<void> _exportAndShareCard() async {
    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);

      // Save item to history as created card
      final item = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'created',
        format: _format,
        value: _valueController.text.trim(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        label: _titleController.text.trim(),
        cardOptions: ShareableCardOptions(
          title: _titleController.text,
          body: _bodyController.text,
          footer: _footerController.text,
          bgType: _bgType,
          bgColor: _colorToHex(_solidColor),
          gradientStart: _colorToHex(_gradientStart),
          gradientEnd: _colorToHex(_gradientEnd),
          textColor: _colorToHex(_textColor),
          borderRadius: _borderRadius,
          borderStyle: _borderStyle,
          showShadow: _showShadow,
          showLogo: _showLogo,
          showValue: _showValue,
        ),
      );
      await widget.historyService.saveItem(item);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${_titleController.text} — Powered by QRagga',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share card: $e')),
        );
      }
    }
  }

  void _saveCurrentAsPreset() {
    final nameController = TextEditingController(text: 'Custom Preset');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Card Preset'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Preset Name', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final template = CardTemplate(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  options: ShareableCardOptions(
                    title: _titleController.text,
                    body: _bodyController.text,
                    footer: _footerController.text,
                    bgType: _bgType,
                    bgColor: _colorToHex(_solidColor),
                    gradientStart: _colorToHex(_gradientStart),
                    gradientEnd: _colorToHex(_gradientEnd),
                    textColor: _colorToHex(_textColor),
                    borderRadius: _borderRadius,
                    borderStyle: _borderStyle,
                    showShadow: _showShadow,
                    showLogo: _showLogo,
                    showValue: _showValue,
                  ),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                );
                await widget.historyService.saveTemplate(template);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preset saved successfully!')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    switch (_borderRadius) {
      case 'none':
        return BorderRadius.zero;
      case 'medium':
        return BorderRadius.circular(16);
      case 'extra-large':
        return BorderRadius.circular(36);
      case 'large':
      default:
        return BorderRadius.circular(24);
    }
  }

  BoxDecoration _getCardDecoration() {
    final radius = _getBorderRadius();
    Border? border;
    if (_borderStyle == 'thin') {
      border = Border.all(color: _textColor.withOpacity(0.4), width: 1.5);
    } else if (_borderStyle == 'dashed') {
      border = Border.all(color: _textColor.withOpacity(0.6), width: 2.0);
    }

    List<BoxShadow>? shadows;
    if (_showShadow) {
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
    }

    if (_bgType == 'solid') {
      return BoxDecoration(
        color: _solidColor,
        borderRadius: radius,
        border: border,
        boxShadow: shadows,
      );
    } else if (_bgType == 'gradient') {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        border: border,
        boxShadow: shadows,
      );
    } else {
      // minimal
      return BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: shadows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = widget.historyService.templates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Designer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Save as Preset',
            onPressed: _saveCurrentAsPreset,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export & Share Card',
            onPressed: _exportAndShareCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Presets row
            if (templates.isNotEmpty) ...[
              Text(
                'Design Presets',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final t = templates[i];
                    return ActionChip(
                      label: Text(t.name),
                      onPressed: () => _applyTemplate(t),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Live WYSIWYG Card Preview
            Center(
              child: RepaintBoundary(
                key: _cardBoundaryKey,
                child: Container(
                  width: 320,
                  constraints: const BoxConstraints(minHeight: 360),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: _getCardDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Logo Icon
                      if (_showLogo)
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Icon(
                            Icons.verified,
                            color: theme.colorScheme.primary,
                            size: 26,
                          ),
                        ),

                      // Title
                      Text(
                        _titleController.text,
                        style: TextStyle(
                          color: _bgType == 'minimal' ? Colors.black87 : _textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Subtitle / Body
                      Text(
                        _bodyController.text,
                        style: TextStyle(
                          color: (_bgType == 'minimal' ? Colors.black87 : _textColor).withOpacity(0.85),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),

                      // Barcode Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: BarcodePreviewWidget(
                          formatId: _format,
                          data: _valueController.text,
                          width: 180,
                          height: 180,
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Value text (optional)
                      if (_showValue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _valueController.text,
                            style: TextStyle(
                              color: _bgType == 'minimal' ? Colors.black87 : _textColor,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 10),

                      // Footer note
                      if (_footerController.text.isNotEmpty)
                        Text(
                          _footerController.text,
                          style: TextStyle(
                            color: (_bgType == 'minimal' ? Colors.black87 : _textColor).withOpacity(0.7),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card Content Customization Fields
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card Text Content', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Card Title', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(labelText: 'Subtitle / Description', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _footerController,
                      decoration: const InputDecoration(labelText: 'Footer Note', border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Style Customizations Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Style & Appearance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Background Style Segments
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'gradient', label: Text('Gradient')),
                        ButtonSegment(value: 'solid', label: Text('Solid')),
                        ButtonSegment(value: 'minimal', label: Text('Minimal')),
                      ],
                      selected: {_bgType},
                      onSelectionChanged: (set) => setState(() => _bgType = set.first),
                    ),
                    const SizedBox(height: 12),

                    // Corner Radius
                    Row(
                      children: [
                        const Text('Rounding: '),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _borderRadius,
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('None (Square)')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'large', child: Text('Large (Default)')),
                            DropdownMenuItem(value: 'extra-large', child: Text('Extra Large')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _borderRadius = v);
                          },
                        ),
                      ],
                    ),

                    // Toggles
                    SwitchListTile(
                      title: const Text('Display Barcode Value Text'),
                      value: _showValue,
                      onChanged: (v) => setState(() => _showValue = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Show Header Verified Badge'),
                      value: _showLogo,
                      onChanged: (v) => setState(() => _showLogo = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Card Drop Shadow'),
                      value: _showShadow,
                      onChanged: (v) => setState(() => _showShadow = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _exportAndShareCard,
              icon: const Icon(Icons.share),
              label: const Text('Export & Share Certificate Card'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
