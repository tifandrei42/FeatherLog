import 'package:featherlog/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The default build (no --dart-define) is the GitHub/sideload channel, which
  // keeps the in-app GitHub update check. The Play build is compiled with
  // --dart-define=FEATHERLOG_DISTRIBUTION=play, which flips these and
  // tree-shakes the update feature out (Play policy: no off-Play update prompts).
  test('defaults to the github channel with the update check enabled', () {
    expect(kDistribution, 'github');
    expect(kIsPlayBuild, isFalse);
    expect(kInAppUpdateCheck, isTrue);
  });
}
