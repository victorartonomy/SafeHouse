import 'package:flutter_test/flutter_test.dart';
import 'package:safe_house/main.dart';

void main() {
  testWidgets('SafeHouse placeholder screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeHouseApp());
    expect(find.text('SafeHouse'), findsOneWidget);
  });
}
