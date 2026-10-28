import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrlcash/screens/cadastro_screen.dart';

void main() {
  testWidgets('CadastroScreen renderiza titulo da etapa 1',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));

    expect(find.text('Dados Pessoais'), findsOneWidget);
  });
}