// Smoke test: the LoginScreen renders its core fields without a live
// Supabase connection. Full auth-flow tests are added with the Auth module.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
