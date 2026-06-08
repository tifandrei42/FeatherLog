import 'package:featherlog/data/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A minimal GitHub `releases/latest` payload.
String _release({
  String tag = 'v1.2.0',
  bool draft = false,
  bool prerelease = false,
}) =>
    '{"tag_name":"$tag","html_url":"https://github.com/x/y/releases/tag/$tag",'
    '"draft":$draft,"prerelease":$prerelease,"body":"Notes here"}';

void main() {
  group('parseLatest', () {
    test('parses a valid stable release', () {
      final info = UpdateService.parseLatest(_release());
      expect(info, isNotNull);
      expect(info!.version, 'v1.2.0');
      expect(info.url, contains('/releases/tag/v1.2.0'));
      expect(info.notes, 'Notes here');
    });

    test('ignores drafts and pre-releases', () {
      expect(UpdateService.parseLatest(_release(draft: true)), isNull);
      expect(UpdateService.parseLatest(_release(prerelease: true)), isNull);
    });

    test('rejects malformed / wrong-shape bodies', () {
      expect(UpdateService.parseLatest('not json'), isNull);
      expect(UpdateService.parseLatest('[]'), isNull);
      expect(UpdateService.parseLatest('{"html_url":"x"}'), isNull); // no tag
      expect(UpdateService.parseLatest('{"tag_name":"v1"}'), isNull); // no url
    });
  });

  group('fetchLatest / checkForUpdate', () {
    test('returns the release on a 200', () async {
      final svc = UpdateService(
        client: MockClient((_) async => http.Response(_release(), 200)),
      );
      final info = await svc.fetchLatest();
      expect(info?.version, 'v1.2.0');
    });

    test('returns null on a non-200 (fails silently)', () async {
      final svc = UpdateService(
        client: MockClient((_) async => http.Response('nope', 404)),
      );
      expect(await svc.fetchLatest(), isNull);
    });

    test('returns null when the network throws', () async {
      final svc = UpdateService(
        client: MockClient((_) async => throw Exception('offline')),
      );
      expect(await svc.fetchLatest(), isNull);
    });

    test('checkForUpdate only returns a strictly newer release', () async {
      final svc = UpdateService(
        client: MockClient((_) async => http.Response(_release(), 200)),
      );
      expect((await svc.checkForUpdate('1.1.0'))?.version, 'v1.2.0');
      expect(await svc.checkForUpdate('1.2.0'), isNull);
      expect(await svc.checkForUpdate('1.3.0'), isNull);
    });
  });
}
