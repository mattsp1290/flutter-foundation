import 'package:flutter_foundation_catalog/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the catalog scaffold', (tester) async {
    await tester.pumpWidget(const CatalogApp());

    expect(find.text('Flutter Foundation catalog scaffold'), findsOneWidget);
  });
}
