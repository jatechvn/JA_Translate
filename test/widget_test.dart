import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/main.dart';

void main() {
  testWidgets('JaTranslateApp mounts without crashing', (tester) async {
    await tester.pumpWidget(const JaTranslateApp());
    expect(find.byType(JaTranslateApp), findsOneWidget);
  });
}
