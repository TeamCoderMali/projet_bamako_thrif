import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bamako_thrift/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BamakoThriftApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
