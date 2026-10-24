import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';
import '../models/card_template.dart';
import '../models/barcode_definition.dart';

class HistoryService extends ChangeNotifier {
  static const String _keyHistory = 'qragga_history_items';
  static const String _keyTemplates = 'qragga_card_templates';

  List<HistoryItem> _items = [];
  List<CardTemplate> _templates = [];
  bool _isLoading = true;

  List<HistoryItem> get items => List.unmodifiable(_items);
  List<CardTemplate> get templates => List.unmodifiable(_templates);
  bool get isLoading => _isLoading;

  HistoryService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load history
    final historyJson = prefs.getString(_keyHistory);
    if (historyJson != null) {
      _items = HistoryItem.listFromJson(historyJson);
    }

    // Load templates
    final templatesJson = prefs.getString(_keyTemplates);
    if (templatesJson != null) {
      _templates = CardTemplate.listFromJson(templatesJson);
    }
    if (_templates.isEmpty) {
      _templates = CardTemplate.getDefaults();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveItem(HistoryItem item) async {
    // If item with same ID exists, update it; otherwise insert at beginning
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.insert(0, item);
    }
    await _persistHistory();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(isFavorite: !current.isFavorite);
      await _persistHistory();
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _persistHistory();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHistory, HistoryItem.listToJson(_items));
  }

  // Template management
  Future<void> saveTemplate(CardTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      _templates[index] = template;
    } else {
      _templates.insert(0, template);
    }
    await _persistTemplates();
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _persistTemplates();
    notifyListeners();
  }

  Future<void> _persistTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTemplates, CardTemplate.listToJson(_templates));
  }

  // Filter helper
  List<HistoryItem> getFilteredItems({
    String query = '',
    String filterType = 'all', // all, scanned, created, favorites
    String categoryFilter = 'all', // all, 1D, 2D
  }) {
    return _items.where((item) {
      // Search match
      final q = query.toLowerCase().trim();
      if (q.isNotEmpty) {
        final matchesValue = item.value.toLowerCase().contains(q);
        final matchesLabel = (item.label ?? '').toLowerCase().contains(q);
        final def = BarcodeRegistry.getById(item.format);
        final matchesFormat = def.name.toLowerCase().contains(q);
        if (!matchesValue && !matchesLabel && !matchesFormat) {
          return false;
        }
      }

      // Filter type match
      if (filterType == 'scanned' && item.type != 'scanned') return false;
      if (filterType == 'created' && item.type != 'created') return false;
      if (filterType == 'favorites' && !item.isFavorite) return false;

      // Category match
      if (categoryFilter != 'all') {
        final def = BarcodeRegistry.getById(item.format);
        if (categoryFilter == '1D' && def.category != BarcodeCategory.oneD) return false;
        if (categoryFilter == '2D' && def.category != BarcodeCategory.twoD) return false;
      }

      return true;
    }).toList();
  }

  // Backup Export JSON string
  String exportBackupJson() {
    return jsonEncode({
      'app': 'QRagga',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'history': _items.map((e) => e.toJson()).toList(),
      'templates': _templates.map((e) => e.toJson()).toList(),
    });
  }

  // Backup Import JSON
  bool importBackupJson(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic> && decoded.containsKey('history')) {
        final List<dynamic> historyList = decoded['history'];
        final importedItems = historyList
            .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();

        // Merge without duplicates based on id
        final existingIds = _items.map((i) => i.id).toSet();
        for (final item in importedItems) {
          if (!existingIds.contains(item.id)) {
            _items.add(item);
          }
        }
        _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _persistHistory();

        if (decoded.containsKey('templates')) {
          final List<dynamic> templateList = decoded['templates'];
          final importedTemplates = templateList
              .map((e) => CardTemplate.fromJson(e as Map<String, dynamic>))
              .toList();
          final existingTemplateIds = _templates.map((t) => t.id).toSet();
          for (final t in importedTemplates) {
            if (!existingTemplateIds.contains(t.id)) {
              _templates.add(t);
            }
          }
          _persistTemplates();
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
