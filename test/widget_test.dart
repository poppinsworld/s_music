import 'package:flutter_test/flutter_test.dart';
import 'package:s_music/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SMusicApp()));
    expect(find.text('S_Music Splash'), findsOneWidget);
  });
}
