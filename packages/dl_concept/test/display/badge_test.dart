import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sem count, mostra um ponto sem texto', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppBadge()));

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('com count, mostra o número', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppBadge(count: 3)));

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('acima de 99, mostra 99+', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppBadge(count: 150)));

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('com color customizada, usa a cor informada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppBadge(count: 1, color: Colors.blue)),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.blue);
  });
}
