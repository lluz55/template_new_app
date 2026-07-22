import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra ícone e mensagem', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppEmptyState(
          icon: Icons.inbox_outlined,
          message: 'Nada por aqui.',
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Nada por aqui.'), findsOneWidget);
  });

  testWidgets('sem iconColor, usa onSurfaceVariant do tema', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppEmptyState(
          icon: Icons.inbox_outlined,
          message: 'Nada por aqui.',
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
    final context = tester.element(find.byType(AppEmptyState));
    expect(icon.color, Theme.of(context).colorScheme.onSurfaceVariant);
  });

  testWidgets('com iconColor, usa a cor informada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppEmptyState(
          icon: Icons.error_outline,
          message: 'Erro ao carregar.',
          iconColor: Colors.red,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, Colors.red);
  });
}
