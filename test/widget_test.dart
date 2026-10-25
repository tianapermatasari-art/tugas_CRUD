
import 'package:flutter_test/flutter_test.dart';
import 'package:crud_rest_api/main.dart';

void main() {
  testWidgets('Aplikasi CRUD dapat dibuka', (WidgetTester tester) async {
    await tester.pumpWidget(const CrudApp());

    expect(find.text('CRUD REST API'), findsOneWidget);
  });
}
