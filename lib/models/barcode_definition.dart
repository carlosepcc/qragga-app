import 'package:barcode/barcode.dart';

enum BarcodeCategory { oneD, twoD }

class BarcodeFormatDefinition {
  final String id;
  final String name;
  final BarcodeCategory category;
  final String description;
  final String placeholder;
  final RegExp? validationRegex;
  final Barcode Function() barcodeFactory;

  const BarcodeFormatDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.placeholder,
    this.validationRegex,
    required this.barcodeFactory,
  });

  bool validate(String text) {
    if (validationRegex == null) return true;
    return validationRegex!.hasMatch(text.trim());
  }
}

class BarcodeRegistry {
  static final List<BarcodeFormatDefinition> definitions = [
    // 2D Codes
    BarcodeFormatDefinition(
      id: 'qrcode',
      name: 'QR Code',
      category: BarcodeCategory.twoD,
      description: 'The standard multi-purpose matrix barcode. Stores URLs, contacts, text, Wi-Fi configuration, etc.',
      placeholder: 'https://example.com',
      barcodeFactory: () => Barcode.qrCode(),
    ),
    BarcodeFormatDefinition(
      id: 'azteccode',
      name: 'Aztec Code',
      category: BarcodeCategory.twoD,
      description: 'Niche square matrix code with central bullseye finder. Ideal for compact areas like transit tickets, boarding passes, and rail documents.',
      placeholder: 'AZTEC-BOARDING-PASS-90210',
      barcodeFactory: () => Barcode.aztec(),
    ),
    BarcodeFormatDefinition(
      id: 'datamatrix',
      name: 'Data Matrix',
      category: BarcodeCategory.twoD,
      description: 'High-density 2D layout. Highly readable even at small physical sizes or under low contrast. Used in electronics, medicine, and aerospace.',
      placeholder: 'SER-A10984-Z920',
      barcodeFactory: () => Barcode.dataMatrix(),
    ),
    BarcodeFormatDefinition(
      id: 'pdf417',
      name: 'PDF417 Code',
      category: BarcodeCategory.twoD,
      description: 'Stacked linear barcode format. Highly secure, capable of storing massive amounts of data. Standard for driver licenses and ID cards.',
      placeholder: 'DL-9302-CARLOS-CARDENAS',
      barcodeFactory: () => Barcode.pdf417(),
    ),

    // 1D Codes
    BarcodeFormatDefinition(
      id: 'code128',
      name: 'Code 128',
      category: BarcodeCategory.oneD,
      description: 'High-density linear barcode. Supports all 128 ASCII characters, making it the default for logistics and inventory.',
      placeholder: 'ZEBRA-128-9843-02',
      barcodeFactory: () => Barcode.code128(),
    ),
    BarcodeFormatDefinition(
      id: 'code39',
      name: 'Code 39',
      category: BarcodeCategory.oneD,
      description: 'Alphanumeric barcode with variable length. Simple and self-checking. Widely used in automotive inventory and manufacturing.',
      placeholder: 'PROD-39-MARK-1',
      validationRegex: RegExp(r'^[A-Z0-9\-\.\ \$\/\+\%]+$'),
      barcodeFactory: () => Barcode.code39(),
    ),
    BarcodeFormatDefinition(
      id: 'ean13',
      name: 'EAN-13',
      category: BarcodeCategory.oneD,
      description: '13-digit European Article Number, worldwide standard for identifying retail products on retail shelf scans.',
      placeholder: '4012345678901',
      validationRegex: RegExp(r'^\d{12,13}$'),
      barcodeFactory: () => Barcode.ean13(),
    ),
    BarcodeFormatDefinition(
      id: 'ean8',
      name: 'EAN-8',
      category: BarcodeCategory.oneD,
      description: '8-digit compact version of EAN, designed for small-sized packaging (like chewing gum, cosmetics, or candy bars).',
      placeholder: '12345670',
      validationRegex: RegExp(r'^\d{7,8}$'),
      barcodeFactory: () => Barcode.ean8(),
    ),
    BarcodeFormatDefinition(
      id: 'upca',
      name: 'UPC-A',
      category: BarcodeCategory.oneD,
      description: '12-digit Universal Product Code, standard barcode format for consumer package tracking in supermarkets and stores.',
      placeholder: '012345678905',
      validationRegex: RegExp(r'^\d{11,12}$'),
      barcodeFactory: () => Barcode.upcA(),
    ),
    BarcodeFormatDefinition(
      id: 'codabar',
      name: 'Codabar',
      category: BarcodeCategory.oneD,
      description: 'Numeric barcode that includes start/stop characters (A, B, C, D). Robust offline scan, used in libraries, blood banks, and FedEx shipping.',
      placeholder: 'A12345678B',
      validationRegex: RegExp(r'^[A-Da-d][0-9\-\$\:\/\.\+]+[A-Da-d]$'),
      barcodeFactory: () => Barcode.codabar(),
    ),
    BarcodeFormatDefinition(
      id: 'itf',
      name: 'Interleaved 2 of 5 (ITF)',
      category: BarcodeCategory.oneD,
      description: 'Numeric-only barcode. Characters are encoded in pairs, so the input string length must be an even number. Heavy carton-label standard.',
      placeholder: '123456789012',
      validationRegex: RegExp(r'^\d+$'),
      barcodeFactory: () => Barcode.itf(),
    ),
  ];

  static BarcodeFormatDefinition getById(String id) {
    return definitions.firstWhere(
      (def) => def.id.toLowerCase() == id.toLowerCase(),
      orElse: () => definitions.first,
    );
  }
}
