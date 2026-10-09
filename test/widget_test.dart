import 'package:flutter_test/flutter_test.dart';
import 'package:wardhelm/main.dart';

void main() {
  testWidgets('WardHelmApp launches and boots smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WardHelmApp());
    // Initial frame shows loading or auth
    expect(find.byType(WardHelmApp), findsOneWidget);
  });
}
