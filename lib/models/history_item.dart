import 'dart:convert';

class PersonalizationOptions {
  final String fgColor;
  final String bgColor;
  final double scale;
  final bool includeText;
  final String? customLabel;
  final bool quietZone;
  final double barHeight;

  const PersonalizationOptions({
    this.fgColor = '#000000',
    this.bgColor = '#FFFFFF',
    this.scale = 3.0,
    this.includeText = true,
    this.customLabel,
    this.quietZone = true,
    this.barHeight = 50.0,
  });

  Map<String, dynamic> toJson() => {
    'fgColor': fgColor,
    'bgColor': bgColor,
    'scale': scale,
    'includeText': includeText,
    'customLabel': customLabel,
    'quietZone': quietZone,
    'barHeight': barHeight,
  };

  factory PersonalizationOptions.fromJson(Map<String, dynamic> json) => PersonalizationOptions(
    fgColor: json['fgColor'] ?? '#000000',
    bgColor: json['bgColor'] ?? '#FFFFFF',
    scale: (json['scale'] as num?)?.toDouble() ?? 3.0,
    includeText: json['includeText'] ?? true,
    customLabel: json['customLabel'],
    quietZone: json['quietZone'] ?? true,
    barHeight: (json['barHeight'] as num?)?.toDouble() ?? 50.0,
  );
}

class ShareableCardOptions {
  final String title;
  final String body;
  final String footer;
  final String bgType; // solid, gradient, minimal
  final String bgColor;
  final String gradientStart;
  final String gradientEnd;
  final String textColor;
  final String borderRadius; // none, medium, large, extra-large
  final String borderStyle; // none, thin, dashed
  final bool showShadow;
  final bool showLogo;
  final bool showValue;

  const ShareableCardOptions({
    this.title = 'QRagga Certificate',
    this.body = 'Scan this code to verify information',
    this.footer = 'Verified Offline • QRagga',
    this.bgType = 'solid',
    this.bgColor = '#FFFFFF',
    this.gradientStart = '#6750A4',
    this.gradientEnd = '#E8DEF8',
    this.textColor = '#000000',
    this.borderRadius = 'large',
    this.borderStyle = 'none',
    this.showShadow = true,
    this.showLogo = true,
    this.showValue = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'footer': footer,
    'bgType': bgType,
    'bgColor': bgColor,
    'gradientStart': gradientStart,
    'gradientEnd': gradientEnd,
    'textColor': textColor,
    'borderRadius': borderRadius,
    'borderStyle': borderStyle,
    'showShadow': showShadow,
    'showLogo': showLogo,
    'showValue': showValue,
  };

  factory ShareableCardOptions.fromJson(Map<String, dynamic> json) => ShareableCardOptions(
    title: json['title'] ?? 'QRagga Certificate',
    body: json['body'] ?? 'Scan this code to verify information',
    footer: json['footer'] ?? 'Verified Offline • QRagga',
    bgType: json['bgType'] ?? 'solid',
    bgColor: json['bgColor'] ?? '#FFFFFF',
    gradientStart: json['gradientStart'] ?? '#6750A4',
    gradientEnd: json['gradientEnd'] ?? '#E8DEF8',
    textColor: json['textColor'] ?? '#000000',
    borderRadius: json['borderRadius'] ?? 'large',
    borderStyle: json['borderStyle'] ?? 'none',
    showShadow: json['showShadow'] ?? true,
    showLogo: json['showLogo'] ?? true,
    showValue: json['showValue'] ?? false,
  );
}

class HistoryItem {
  final String id;
  final String type; // 'scanned' | 'created'
  final String format; // 'qrcode', 'azteccode', etc.
  final String value;
  final int timestamp;
  final String? label;
  final String? categoryTag;
  final bool isFavorite;
  final PersonalizationOptions? personalization;
  final ShareableCardOptions? cardOptions;

  const HistoryItem({
    required this.id,
    required this.type,
    required this.format,
    required this.value,
    required this.timestamp,
    this.label,
    this.categoryTag,
    this.isFavorite = false,
    this.personalization,
    this.cardOptions,
  });

  HistoryItem copyWith({
    String? id,
    String? type,
    String? format,
    String? value,
    int? timestamp,
    String? label,
    String? categoryTag,
    bool? isFavorite,
    PersonalizationOptions? personalization,
    ShareableCardOptions? cardOptions,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      format: format ?? this.format,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      categoryTag: categoryTag ?? this.categoryTag,
      isFavorite: isFavorite ?? this.isFavorite,
      personalization: personalization ?? this.personalization,
      cardOptions: cardOptions ?? this.cardOptions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'format': format,
    'value': value,
    'timestamp': timestamp,
    'label': label,
    'categoryTag': categoryTag,
    'isFavorite': isFavorite,
    'personalization': personalization?.toJson(),
    'cardOptions': cardOptions?.toJson(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    type: json['type'] ?? 'scanned',
    format: json['format'] ?? 'qrcode',
    value: json['value'] ?? '',
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    label: json['label'],
    categoryTag: json['categoryTag'],
    isFavorite: json['isFavorite'] ?? false,
    personalization: json['personalization'] != null
        ? PersonalizationOptions.fromJson(json['personalization'])
        : null,
    cardOptions: json['cardOptions'] != null
        ? ShareableCardOptions.fromJson(json['cardOptions'])
        : null,
  );

  static List<HistoryItem> listFromJson(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<HistoryItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
