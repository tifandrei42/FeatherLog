import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';
import '../data/update_service.dart';
import '../domain/version_compare.dart';
import 'data_providers.dart';

/// The installed app version (e.g. "1.2.0"), read once from the platform.
/// Empty on web (the web demo is updated by redeploy, not by this flow).
final appVersionProvider = FutureProvider<String>((ref) async {
  if (kIsWeb) return '';
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// The available update, or null when: update checks are off, there is no newer
/// release, the newer release was dismissed, or the check failed/offline.
///
/// Gated on the two relevant [Settings] fields via `select`, so unrelated
/// settings changes (units, theme, …) don't trigger a fresh network call. When
/// checks are off this short-circuits to null and never touches the network —
/// preserving the zero-network default.
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  // Compiled out of the Play build (Google handles updates there, and steering
  // users to a GitHub APK would violate Play policy). const → tree-shaken.
  if (kIsWeb || !kInAppUpdateCheck) return null;

  final gate = ref.watch(
    settingsProvider.select((s) {
      final v = s.value;
      return (
        enabled: v?.checkUpdates ?? false,
        dismissed: v?.dismissedUpdateVersion,
      );
    }),
  );
  if (!gate.enabled) return null;

  final info = await const UpdateService().fetchLatest();
  if (info == null) return null;

  final current = await ref.watch(appVersionProvider.future);
  if (current.isEmpty || !isNewer(info.version, current)) return null;

  // Respect a previously dismissed version (compare normalised, so 'v1.2.0' and
  // '1.2.0' match).
  final dismissed = gate.dismissed;
  if (dismissed != null &&
      parseVersion(dismissed).join('.') ==
          parseVersion(info.version).join('.')) {
    return null;
  }
  return info;
});
