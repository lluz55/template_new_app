import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o título', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppSectionHeader(title: 'Categoria'),
      ),
    );

    expect(find.text('Categoria'), findsOneWidget);
  });

  testWidgets('sem trailing, não quebra', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppSectionHeader(title: 'Sem ação')),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('com trailing, mostra o widget informado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppSectionHeader(
          title: 'Com ação',
          trailing: TextButton(onPressed: () {}, child: const Text('ver tudo')),
        ),
      ),
    );

    expect(find.text('ver tudo'), findsOneWidget);
  });
}
