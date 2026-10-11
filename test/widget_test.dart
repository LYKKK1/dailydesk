import 'package:dailydesk/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app builds and shows placeholder text', (tester) async {
    await tester.pumpWidget(const DailyDeskApp());

    expect(find.text('DailyDesk'), findsOneWidget);
  });
}
