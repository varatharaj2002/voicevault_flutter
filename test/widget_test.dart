import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voicevault/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DictationApp());

    // Verify that the initial screen is the SignupPage.
    expect(find.text('Sign Up'), findsOneWidget); // Adjust text if different in SignupPage
  });
}
