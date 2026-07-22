import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildList(List<String> items, {required VoidCallback onDismiss}) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            for (final item in items)
              AppDismissibleListItem(
                key: ValueKey(item),
                confirmTitle: 'Remover $item?',
                cancelLabel: 'Cancelar',
                confirmLabel: 'Remover',
                onConfirmedDismiss: onDismiss,
                child: ListTile(title: Text(item)),
              ),
          ],
        ),
      ),
    );
  }

  testWidgets('swipe + confirmar chama onConfirmedDismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      buildList(['item A'], onDismiss: () => dismissed = true),
    );

    await tester.drag(find.text('item A'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });

  testWidgets('swipe + cancelar não chama onConfirmedDismiss e o item volta',
      (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      buildList(['item A'], onDismiss: () => dismissed = true),
    );

    await tester.drag(find.text('item A'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(dismissed, isFalse);
    expect(find.text('item A'), findsOneWidget);
  });

  testWidgets('mostra a mensagem de confirmação quando informada',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDismissibleListItem(
            key: const ValueKey('a'),
            confirmTitle: 'Remover?',
            confirmMessage: 'Isso não pode ser desfeito.',
            cancelLabel: 'Cancelar',
            confirmLabel: 'Remover',
            onConfirmedDismiss: () {},
            child: const ListTile(title: Text('item A')),
          ),
        ),
      ),
    );

    await tester.drag(find.text('item A'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Isso não pode ser desfeito.'), findsOneWidget);
  });
}
