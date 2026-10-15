import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sekolah_mobile/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('LoginScreen displays title and input fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Sistem Manajemen Sekolah'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
  });
}
