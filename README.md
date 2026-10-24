# QRagga (Flutter)

A fully offline, privacy-first Barcode & QR Code Reader, Creator, and Certificate Card Designer built with Flutter and Material You (M3).

## ✨ Features

- **2D Matrix Codes**:
  - **QR Code**: Standard multi-purpose matrix. Custom foreground & background colors, embedded center logo (avatar/icon), error correction levels (L, M, Q, H), quiet zone margin, SVG & PNG export.
  - **Aztec Code**: High-density compact matrix for ticketing and boarding passes.
  - **Data Matrix**: Industrial square matrix used in electronics, logistics, and medical equipment.
  - **PDF417**: High-capacity stacked linear format for driver licenses and ID cards.

- **1D Barcodes**:
  - **Code 128**: High-density logistics barcode with full ASCII support.
  - **Code 39**: Alphanumeric barcode with variable length.
  - **EAN-13 & EAN-8**: Global retail packaging standards with syntax validation.
  - **UPC-A**: 12-digit standard North American retail format.
  - **Codabar**: Robust format used in libraries, blood banks, and transit.
  - **ITF (Interleaved 2 of 5)**: Paired numeric code for shipping cartons.

- **Quick Content Presets**:
  - Website / URL (with domain extraction)
  - Wi-Fi Network (WPA, WEP, Open, SSID, password, hidden)
  - Contact Card (vCard 3.0)
  - Email (mailto:)
  - SMS Message
  - Telephone dialer
  - Geolocation coordinates

- **Certificate & Shareable Card Designer**:
  - Wrap any barcode in a shareable card certificate.
  - Custom titles, subtitles, and footer notes.
  - Solid, Gradient, and Minimalist backgrounds.
  - Customizable border styles and corner radii.
  - Save and load design presets.
  - High-res image generation (RepaintBoundary -> PNG) and direct native sharing (`share_plus`).

- **Camera & Gallery Scanner**:
  - Live viewfinder with `mobile_scanner`.
  - Torch / Flashlight toggle.
  - Camera switch (Front / Rear).
  - Scan directly from gallery images.
  - Haptic feedback and instant detail bottom sheet.

- **Offline History & Storage**:
  - All scans and creations stored locally (`shared_preferences`).
  - Search by text, format name, or tag.
  - Filter by Scanned, Created, Favorites, 1D, and 2D.
  - Full backup export and import in JSON format.
  - 100% offline with zero cloud telemetry.

- **Material You Dynamic Theming**:
  - Customizable seed colors (Material 3 color generation).
  - Light, Dark, and System theme modes.

---

## 🚀 How to Run in Android Studio

1. **Clone or Open Project**:
   - Open Android Studio.
   - Select **Open** and choose this project root directory.

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on Emulator or Device**:
   - Select an Android Virtual Device (or physical Android/iOS phone).
   - Press **Run** (or `Shift + F10`) or run from terminal:
     ```bash
     flutter run
     ```

## 📦 Project Structure

```
├── android/            # Android platform configuration & permissions
├── ios/                # iOS Runner & permissions
├── lib/
│   ├── main.dart       # App entry point, M3 themes
│   ├── models/
│   │   ├── barcode_definition.dart  # 1D & 2D formats, regex, barcode factories
│   │   ├── history_item.dart        # Offline history model & serialization
│   │   └── card_template.dart       # Card design presets
│   ├── services/
│   │   ├── history_service.dart     # Offline storage, search, JSON backup
│   │   └── theme_service.dart       # Material You theme & mode persistence
│   ├── widgets/
│   │   ├── barcode_preview_widget.dart # Barcode & QR rendering
│   │   └── content_type_dialog.dart    # Quick formatters (WiFi, vCard, etc.)
│   └── screens/
│       ├── home_screen.dart         # NavigationBar tabs
│       ├── creator_screen.dart      # Generator with live preview & styling
│       ├── scanner_screen.dart      # Camera & gallery scanner
│       ├── card_builder_screen.dart # Certificate & card designer
│       ├── history_screen.dart      # Archives, favorites & backups
│       └── settings_screen.dart     # Theme seed colors & preferences
├── pubspec.yaml        # Flutter packages & assets
└── test/               # Flutter widget tests
```
