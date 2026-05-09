import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/app/app.dart';

void main() {
  testWidgets('MediCare app launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MedicareApp()));
    expect(find.byType(MedicareApp), findsOneWidget);
  });
}
