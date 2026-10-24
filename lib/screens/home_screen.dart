import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/theme_service.dart';
import 'creator_screen.dart';
import 'scanner_screen.dart';
import 'card_builder_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final HistoryService historyService;
  final ThemeService themeService;

  const HomeScreen({
    super.key,
    required this.historyService,
    required this.themeService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Stored inputs when transitioning between tabs (e.g. from Scanner or History to Creator / Card Builder)
  String _creatorInitialValue = 'https://qragga.hivepen.com';
  String _creatorInitialFormat = 'qrcode';

  String _cardInitialValue = 'https://qragga.hivepen.com';
  String _cardInitialFormat = 'qrcode';

  void _onRecallToCreator(String value, String format) {
    setState(() {
      _creatorInitialValue = value;
      _creatorInitialFormat = format;
      _currentIndex = 0; // Switch to Creator tab
    });
  }

  void _onOpenCardBuilder(String value, String format) {
    setState(() {
      _cardInitialValue = value;
      _cardInitialFormat = format;
      _currentIndex = 2; // Switch to Card Builder tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CreatorScreen(
        historyService: widget.historyService,
        initialValue: _creatorInitialValue,
        initialFormat: _creatorInitialFormat,
        onOpenCardBuilder: _onOpenCardBuilder,
      ),
      ScannerScreen(
        historyService: widget.historyService,
        onRecallToCreator: _onRecallToCreator,
      ),
      CardBuilderScreen(
        historyService: widget.historyService,
        initialValue: _cardInitialValue,
        initialFormat: _cardInitialFormat,
      ),
      HistoryScreen(
        historyService: widget.historyService,
        onRecallToCreator: _onRecallToCreator,
        onOpenCardBuilder: _onOpenCardBuilder,
      ),
      SettingsScreen(
        themeService: widget.themeService,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
