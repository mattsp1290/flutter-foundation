import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel compiles', () {
    expect(
      const BirbTextFormField(label: 'Display name'),
      isA<BirbTextFormField>(),
    );
  });
}
