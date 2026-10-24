import 'package:flutter/material.dart';
import 'services/history_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final historyService = HistoryService();
  final themeService = ThemeService();

  runApp(QRaggaApp(
    historyService: historyService,
    themeService: themeService,
  ));
}

class QRaggaApp extends StatelessWidget {
  final HistoryService historyService;
  final ThemeService themeService;

  const QRaggaApp({
    super.key,
    required this.historyService,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'QRagga',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeService.seedColor,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeService.seedColor,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          home: HomeScreen(
            historyService: historyService,
            themeService: themeService,
          ),
        );
      },
    );
  }
}
