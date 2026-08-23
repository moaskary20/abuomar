import 'package:flutter_test/flutter_test.dart';

import 'package:store_mobile/app.dart';

void main() {
  testWidgets('يعرض اسم المتجر في الرئيسية', (WidgetTester tester) async {
    await tester.pumpWidget(const AboOmarApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('حلوانى ابوعمر'), findsWidgets);
  });
}
