import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/main.dart';

void main() {
  testWidgets('LEON app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LeonApp()),
    );
    // The app should render without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
