import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Future<bool>> openDialog(
    WidgetTester tester, {
    String? message,
    bool destructive = false,
  }) async {
    late Future<bool> dialogFuture;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              dialogFuture = showAppConfirmDialog(
                context,
                title: 'Remover item?',
                message: message,
                cancelLabel: 'Cancelar',
                confirmLabel: 'Remover',
                destructive: destructive,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    return dialogFuture;
  }

  testWidgets('confirmar retorna true', (tester) async {
    final dialogFuture = await openDialog(tester, message: 'tem certeza?');
    expect(find.text('tem certeza?'), findsOneWidget);
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(await dialogFuture, isTrue);
  });

  testWidgets('cancelar retorna false', (tester) async {
    final dialogFuture = await openDialog(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await dialogFuture, isFalse);
  });

  testWidgets('sem message, content fica vazio', (tester) async {
    await openDialog(tester);
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.content, isNull);
  });

  testWidgets('destructive usa colorScheme.error no botão de confirmar',
      (tester) async {
    await openDialog(tester, destructive: true);
    final button = tester.widget<FilledButton>(find.widgetWithText(
      FilledButton,
      'Remover',
    ));
    final context = tester.element(find.byType(AlertDialog));
    final colorScheme = Theme.of(context).colorScheme;
    expect(
      button.style?.backgroundColor?.resolve({}),
      colorScheme.error,
    );
  });
}
