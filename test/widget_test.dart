import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kapsa_app/app.dart';

void main() {
  testWidgets('App renders Home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KapsaApp()),
    );

    expect(find.text('Good Morning,\nAlex'), findsOneWidget);
  });
}
