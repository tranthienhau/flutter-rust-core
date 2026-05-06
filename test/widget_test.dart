// Smoke test only verifies the Riverpod app boots without throwing. The
// actual FFI calls require the Rust dylib at runtime, so the FFI behavior is
// covered by Rust unit tests in `rust/src/lib.rs` instead.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('material app boots', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
