import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o conteúdo do builder e retorna o valor ao fechar',
      (tester) async {
    late Future<String?> sheetFuture;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              sheetFuture = showAppBottomSheet<String>(
                context,
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).pop('valor'),
                  child: const Text('fechar'),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text('fechar'), findsOneWidget);

    await tester.tap(find.text('fechar'));
    await tester.pumpAndSettle();
    expect(await sheetFuture, 'valor');
  });
}
