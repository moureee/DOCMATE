import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'DocMate basic interface test',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('DocMate'),
            ),
          ),
        ),
      );

      expect(
        find.text('DocMate'),
        findsOneWidget,
      );
    },
  );
}
