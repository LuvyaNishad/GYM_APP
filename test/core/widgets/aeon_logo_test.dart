import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/widgets/aeon_logo.dart';
import 'package:leon/core/widgets/acrylic_surface.dart';

void main() {
  testWidgets('AeonLogo renders with correct semantics and requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AeonLogo(
              size: 120.0,
              showGlow: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AeonLogo), findsOneWidget);
    expect(find.bySemanticsLabel('AEON logo'), findsOneWidget);

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AeonLogo),
        matching: find.byType(Container),
      ),
    );
    expect(container.constraints?.maxWidth, equals(120.0));
    expect(container.constraints?.maxHeight, equals(120.0));
  });

  testWidgets('AcrylicSurface renders child with backdrop filter and specular border', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AcrylicSurface(
            child: Text(
              'Acrylic Panel Content',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AcrylicSurface), findsOneWidget);
    expect(find.text('Acrylic Panel Content'), findsOneWidget);
  });
}
