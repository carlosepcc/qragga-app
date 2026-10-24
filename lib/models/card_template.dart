import 'dart:convert';
import 'history_item.dart';

class CardTemplate {
  final String id;
  final String name;
  final ShareableCardOptions options;
  final int timestamp;

  const CardTemplate({
    required this.id,
    required this.name,
    required this.options,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'options': options.toJson(),
    'timestamp': timestamp,
  };

  factory CardTemplate.fromJson(Map<String, dynamic> json) => CardTemplate(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] ?? 'Preset',
    options: ShareableCardOptions.fromJson(json['options'] ?? {}),
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
  );

  static List<CardTemplate> listFromJson(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => CardTemplate.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<CardTemplate> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<CardTemplate> getDefaults() {
    return [
      CardTemplate(
        id: 'default_purple',
        name: 'Material Purple',
        options: const ShareableCardOptions(
          title: 'QRagga Certificate',
          body: 'Scan this code to verify information',
          footer: 'Verified Offline • QRagga',
          bgType: 'gradient',
          bgColor: '#6750A4',
          gradientStart: '#6750A4',
          gradientEnd: '#E8DEF8',
          textColor: '#FFFFFF',
          borderRadius: 'large',
          borderStyle: 'none',
          showShadow: true,
          showLogo: true,
          showValue: false,
        ),
        timestamp: 1,
      ),
      CardTemplate(
        id: 'default_minimal',
        name: 'Clean Minimalist',
        options: const ShareableCardOptions(
          title: 'Direct Link',
          body: 'Point your camera to scan',
          footer: 'Digital Passport',
          bgType: 'minimal',
          bgColor: '#FFFFFF',
          gradientStart: '#FFFFFF',
          gradientEnd: '#F3F4F6',
          textColor: '#111827',
          borderRadius: 'medium',
          borderStyle: 'thin',
          showShadow: false,
          showLogo: true,
          showValue: true,
        ),
        timestamp: 2,
      ),
      CardTemplate(
        id: 'default_sunset',
        name: 'Sunset Orange',
        options: const ShareableCardOptions(
          title: 'VIP Pass',
          body: 'Special access coupon or boarding credential',
          footer: 'Valid on event date only',
          bgType: 'gradient',
          bgColor: '#F43F5E',
          gradientStart: '#F43F5E',
          gradientEnd: '#FB923C',
          textColor: '#FFFFFF',
          borderRadius: 'extra-large',
          borderStyle: 'dashed',
          showShadow: true,
          showLogo: true,
          showValue: false,
        ),
        timestamp: 3,
      ),
    ];
  }
}
