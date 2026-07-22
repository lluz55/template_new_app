import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () => showAppSnackBar(context, 'primeira'),
                  child: const Text('mostrar 1'),
                ),
                ElevatedButton(
                  onPressed: () => showAppSnackBar(context, 'segunda'),
                  child: const Text('mostrar 2'),
                ),
              ],
            ),
          ),
        ),
      );

  testWidgets('mostra a mensagem', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('mostrar 1'));
    await tester.pump();
    expect(find.text('primeira'), findsOneWidget);
  });

  testWidgets('nova chamada esconde a SnackBar anterior', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('mostrar 1'));
    await tester.pump();
    await tester.tap(find.text('mostrar 2'));
    await tester.pump();
    expect(find.widgetWithText(SnackBar, 'primeira'), findsNothing);
    expect(find.widgetWithText(SnackBar, 'segunda'), findsOneWidget);
  });
}
