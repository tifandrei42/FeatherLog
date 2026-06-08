/// Pure-Dart semantic-version comparison for the update check.
///
/// No Flutter/IO imports (see DESIGN.md §1) so it's trivially unit-testable.
/// Tolerant of the shapes we actually meet: a leading `v` (release tags like
/// `v1.2.0`), and a build/pre-release suffix (`1.2.0+5`, `1.2.0-beta`) which is
/// ignored — FeatherLog ships plain `MAJOR.MINOR.PATCH` releases.
library;

/// Returns true if [candidate] is a strictly newer version than [current].
///
/// Compares MAJOR, then MINOR, then PATCH numerically. Missing parts count as
/// 0 (`1.2` == `1.2.0`); unparseable parts count as 0 so a malformed string can
/// never spuriously trigger an "update available" prompt.
bool isNewer(String candidate, String current) {
  final a = parseVersion(candidate);
  final b = parseVersion(current);
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// Parses a version string into `[major, minor, patch]`, tolerating a leading
/// `v`/`V` and ignoring any `+build` / `-prerelease` suffix.
List<int> parseVersion(String version) {
  var s = version.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  // Drop build (+...) and pre-release (-...) metadata.
  s = s.split('+').first.split('-').first;
  final parts = s.split('.');
  final out = [0, 0, 0];
  for (var i = 0; i < 3 && i < parts.length; i++) {
    out[i] = int.tryParse(parts[i].trim()) ?? 0;
  }
  return out;
}
