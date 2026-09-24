import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';

void main() {
  group('AppOutlinedCard', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppOutlinedCard(child: Text('Card content'))),
        ),
      );

      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppOutlinedCard(
              onTap: () => tapped = true,
              child: const Text('Card content'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Card content'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not wrap in InkWell when onTap is not provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppOutlinedCard(child: Text('Card content'))),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });
  });
}
