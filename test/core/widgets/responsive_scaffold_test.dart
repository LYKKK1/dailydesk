import 'package:dailydesk/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('width above 900 uses desktop body', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScaffold(
          desktopBody: Text('DESKTOP'),
          mobileBody: Text('MOBILE'),
        ),
      ),
    );

    expect(find.text('DESKTOP'), findsOneWidget);
    expect(find.text('MOBILE'), findsNothing);
  });

  testWidgets('width at or below 900 uses mobile navigation', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveScaffold(
          desktopBody: Text('DESKTOP'),
          mobileBody: Text('MOBILE'),
        ),
      ),
    );

    expect(find.text('MOBILE'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
