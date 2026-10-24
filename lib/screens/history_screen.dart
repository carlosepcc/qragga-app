import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/history_item.dart';
import '../models/barcode_definition.dart';
import '../services/history_service.dart';
import '../widgets/barcode_preview_widget.dart';

class HistoryScreen extends StatefulWidget {
  final HistoryService historyService;
  final void Function(String value, String format)? onRecallToCreator;
  final void Function(String value, String format)? onOpenCardBuilder;

  const HistoryScreen({
    super.key,
    required this.historyService,
    this.onRecallToCreator,
    this.onOpenCardBuilder,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all'; // all, scanned, created, favorites
  String _categoryFilter = 'all'; // all, 1D, 2D

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    try {
      final jsonStr = widget.historyService.exportBackupJson();
      await Share.share(
        jsonStr,
        subject: 'QRagga-Offline-Backup-${DateFormat('yyyyMMdd').format(DateTime.now())}.json',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final success = widget.historyService.importBackupJson(content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Backup imported successfully!' : 'Invalid backup format.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will remove all saved scans and creations from local storage. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await widget.historyService.clearAll();
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All history cleared.')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(HistoryItem item) {
    final theme = Theme.of(context);
    final def = BarcodeRegistry.getById(item.format);
    final isUrl = item.value.startsWith('http://') || item.value.startsWith('https://');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    item.type == 'scanned' ? Icons.qr_code_scanner : Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    def.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      item.isFavorite ? Icons.star : Icons.star_border,
                      color: item.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () {
                      widget.historyService.toggleFavorite(item.id);
                      Navigator.pop(ctx);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Code preview thumbnail
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: BarcodePreviewWidget(
                    formatId: item.format,
                    data: item.value,
                    width: 140,
                    height: 140,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  item.value,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Recorded: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(item.timestamp))}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isUrl)
                    FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(item.value);
                        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Open URL'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Share.share(item.value),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                  ),
                  if (widget.onRecallToCreator != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onRecallToCreator!(item.value, item.format);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Creator'),
                    ),
                  if (widget.onOpenCardBuilder != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onOpenCardBuilder!(item.value, item.format);
                      },
                      icon: const Icon(Icons.style, size: 16),
                      label: const Text('Card Designer'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      widget.historyService.deleteItem(item.id);
                      Navigator.pop(ctx);
                    },
                    tooltip: 'Delete item',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.historyService.getFilteredItems(
      query: _searchController.text,
      filterType: _filterType,
      categoryFilter: _categoryFilter,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Archives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Backup JSON',
            onPressed: _importBackup,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Backup JSON',
            onPressed: _exportBackup,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history by value or format...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
          ),

          // Filter Segment Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 6),
                _buildFilterChip('Scanned', 'scanned'),
                const SizedBox(width: 6),
                _buildFilterChip('Created', 'created'),
                const SizedBox(width: 6),
                _buildFilterChip('Favorites', 'favorites'),
                const SizedBox(width: 12),
                const Text('|', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                _buildCategoryChip('All Formats', 'all'),
                const SizedBox(width: 6),
                _buildCategoryChip('2D Matrix', '2D'),
                const SizedBox(width: 6),
                _buildCategoryChip('1D Barcode', '1D'),
              ],
            ),
          ),
          const Divider(height: 16),

          // History items list
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 54, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No history records found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scanned codes and generated barcodes will appear here offline.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final def = BarcodeRegistry.getById(item.format);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          onTap: () => _showItemDetails(item),
                          leading: CircleAvatar(
                            backgroundColor: item.type == 'scanned'
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.primaryContainer,
                            child: Icon(
                              item.type == 'scanned' ? Icons.qr_code_scanner : Icons.add_circle,
                              size: 18,
                              color: item.type == 'scanned'
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                def.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            item.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  item.isFavorite ? Icons.star : Icons.star_border,
                                  color: item.isFavorite ? Colors.amber : null,
                                  size: 20,
                                ),
                                onPressed: () => widget.historyService.toggleFavorite(item.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => widget.historyService.deleteItem(item.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filterType == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _filterType = value);
      },
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final selected = _categoryFilter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _categoryFilter = value);
      },
    );
  }
}
