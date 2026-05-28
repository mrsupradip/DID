import 'package:flutter_test/flutter_test.dart';

import 'package:did/main.dart';

void main() {
  testWidgets('App shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DIDApp());
    await tester.pump();

    expect(find.text('BUILD • CONNECT • GROW'), findsOneWidget);
  });
}
