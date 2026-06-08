import 'package:featherlog/domain/version_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewer', () {
    test('detects a newer patch / minor / major', () {
      expect(isNewer('1.2.1', '1.2.0'), isTrue);
      expect(isNewer('1.3.0', '1.2.9'), isTrue);
      expect(isNewer('2.0.0', '1.9.9'), isTrue);
    });

    test('equal or older is not newer', () {
      expect(isNewer('1.2.0', '1.2.0'), isFalse);
      expect(isNewer('1.1.0', '1.2.0'), isFalse);
      expect(isNewer('0.9.9', '1.0.0'), isFalse);
    });

    test('compares numerically, not lexically', () {
      // 10 > 9 even though "10" < "9" as strings.
      expect(isNewer('1.10.0', '1.9.0'), isTrue);
      expect(isNewer('1.9.0', '1.10.0'), isFalse);
    });

    test('tolerates a leading v', () {
      expect(isNewer('v1.2.0', '1.1.0'), isTrue);
      expect(isNewer('v1.2.0', 'v1.2.0'), isFalse);
    });

    test('ignores build / pre-release suffixes', () {
      expect(isNewer('1.2.0+5', '1.2.0'), isFalse);
      expect(isNewer('1.2.0', '1.2.0-beta'), isFalse);
      expect(isNewer('1.2.1', '1.2.0+99'), isTrue);
    });

    test('treats missing parts as zero', () {
      expect(isNewer('1.2', '1.2.0'), isFalse);
      expect(isNewer('1.2.1', '1.2'), isTrue);
    });

    test('a malformed string never triggers an update', () {
      expect(isNewer('garbage', '1.0.0'), isFalse);
      expect(isNewer('', '1.0.0'), isFalse);
    });
  });

  group('parseVersion', () {
    test('parses the common shapes', () {
      expect(parseVersion('v1.2.0'), [1, 2, 0]);
      expect(parseVersion('1.2.0+5'), [1, 2, 0]);
      expect(parseVersion('1.2.0-beta.1'), [1, 2, 0]);
      expect(parseVersion('3'), [3, 0, 0]);
      expect(parseVersion('nonsense'), [0, 0, 0]);
    });
  });
}
