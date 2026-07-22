import 'package:dl_concept/dl_concept.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('breakpointForWidth', () {
    test('599 é compact (limite inferior de medium - 1)', () {
      expect(breakpointForWidth(599), AppBreakpoint.compact);
    });

    test('600 é medium (limite inferior de medium)', () {
      expect(breakpointForWidth(600), AppBreakpoint.medium);
    });

    test('839 é medium (limite superior de medium)', () {
      expect(breakpointForWidth(839), AppBreakpoint.medium);
    });

    test('840 é expanded (limite inferior de expanded)', () {
      expect(breakpointForWidth(840), AppBreakpoint.expanded);
    });
  });
}
