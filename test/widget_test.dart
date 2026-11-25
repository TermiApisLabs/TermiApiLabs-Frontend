// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:termiapislabs_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:termiapislabs_frontend/features/auth/presentation/pages/auth_pages.dart';

void main() {
  testWidgets('renders a technical screen shell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('TermiAPILabs')),
      ),
    );

    expect(find.text('TermiAPILabs'), findsOneWidget);
  });

  testWidgets('recovery page does not promise code delivery', (tester) async {
    final auth = AuthController();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: const MaterialApp(home: ForgotPasswordPage()),
      ),
    );

    expect(find.textContaining('você receberá instruções'), findsNothing);
    expect(find.text('SOLICITAR CÓDIGO'), findsOneWidget);
  });
}
