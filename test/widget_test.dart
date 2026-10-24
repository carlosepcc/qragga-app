import 'package:flutter_test/flutter_test.dart';
import 'package:qragga/main.dart';
import 'package:qragga/services/history_service.dart';
import 'package:qragga/services/theme_service.dart';

void main() {
  testWidgets('QRagga initial widget render test', (WidgetTester tester) async {
    final historyService = HistoryService();
    final themeService = ThemeService();

    await tester.pumpWidget(QRaggaApp(
      historyService: historyService,
      themeService: themeService,
    ));

    expect(find.text('Barcode Creator'), findsOneWidget);
  });
}
