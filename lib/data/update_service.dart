import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/version_compare.dart';

/// A newer release available on GitHub.
class UpdateInfo {
  const UpdateInfo({required this.version, required this.url, this.notes});

  /// The release tag, e.g. `v1.2.0`.
  final String version;

  /// The human-facing release page (where the APKs live).
  final String url;

  /// The release notes (Markdown), if any.
  final String? notes;
}

/// Checks GitHub for a newer FeatherLog release.
///
/// This is the app's **only** network call, and it only runs when the user has
/// opted in (see [Settings.checkUpdates] / PRIVACY.md). It hits the public
/// `releases/latest` endpoint anonymously — no auth, no personal data sent — and
/// fails silently (returns null) on any error so a flaky network never disrupts
/// the app. The version comparison lives in pure `domain/version_compare.dart`.
class UpdateService {
  const UpdateService({
    this.owner = 'tifandrei42',
    this.repo = 'FeatherLog',
    this.client,
  });

  final String owner;
  final String repo;

  /// Injectable for tests; a default [http.Client] is used when null.
  final http.Client? client;

  Uri get _latestUri =>
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');

  /// Fetches the latest release, or null on any failure (network, non-200,
  /// malformed body). Never throws.
  Future<UpdateInfo?> fetchLatest() async {
    final c = client ?? http.Client();
    try {
      final resp = await c
          .get(_latestUri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      return parseLatest(resp.body);
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  /// Returns the latest release if it is strictly newer than [currentVersion],
  /// otherwise null. Convenience over [fetchLatest] + [isNewer].
  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final latest = await fetchLatest();
    if (latest == null) return null;
    return isNewer(latest.version, currentVersion) ? latest : null;
  }

  /// Parses a GitHub `releases/latest` JSON body into an [UpdateInfo], or null
  /// if it isn't the expected shape. Pure (no IO) so it's unit-testable.
  static UpdateInfo? parseLatest(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    // Ignore drafts / pre-releases — only stable releases should prompt.
    if (decoded['draft'] == true || decoded['prerelease'] == true) return null;
    final tag = decoded['tag_name'];
    final url = decoded['html_url'];
    if (tag is! String || tag.isEmpty || url is! String || url.isEmpty) {
      return null;
    }
    final notes = decoded['body'];
    return UpdateInfo(
      version: tag,
      url: url,
      notes: notes is String && notes.isNotEmpty ? notes : null,
    );
  }
}
