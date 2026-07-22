import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Retorna a `Future` pendente do diálogo (sem `await`, para não travar
  // esperando o usuário responder) — o teste dá `await` nela só depois de
  // interagir (digitar/tocar cancelar ou confirmar).
  Future<Future<String?>> openDialog(
    WidgetTester tester, {
    String initialText = '',
    int minLines = 1,
    int maxLines = 1,
  }) async {
    late Future<String?> dialogFuture;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              dialogFuture = showAppTextInputDialog(
                context,
                title: 'Título',
                cancelLabel: 'Cancelar',
                confirmLabel: 'Confirmar',
                hint: 'Dica',
                initialText: initialText,
                minLines: minLines,
                maxLines: maxLines,
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

  testWidgets('confirmar retorna o texto digitado', (tester) async {
    final dialogFuture = await openDialog(tester);
    await tester.enterText(find.byType(TextField), 'novo item');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(await dialogFuture, 'novo item');
  });

  testWidgets('cancelar retorna null', (tester) async {
    final dialogFuture = await openDialog(tester, initialText: 'rascunho');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await dialogFuture, isNull);
  });

  testWidgets('campo de uma linha confirma com onSubmitted', (tester) async {
    final dialogFuture = await openDialog(tester);
    await tester.enterText(find.byType(TextField), 'via enter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(await dialogFuture, 'via enter');
  });

  testWidgets('multilinha não confirma com onSubmitted', (tester) async {
    await openDialog(tester, minLines: 3, maxLines: 6);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.onSubmitted, isNull);
  });
}
