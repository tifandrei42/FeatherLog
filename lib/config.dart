/// Build-time configuration that varies by distribution channel.
///
/// FeatherLog ships through two channels: the Google Play Store and direct
/// GitHub Releases (sideload / Obtainium). A few behaviours must differ between
/// them — these are compile-time constants set via `--dart-define`, so the
/// disabled branches tree-shake out of the build entirely (nothing is merely
/// hidden at runtime).
library;

/// The distribution channel. Defaults to `github` (the sideload/Obtainium
/// build); the Play build is compiled with
/// `--dart-define=FEATHERLOG_DISTRIBUTION=play`.
const String kDistribution = String.fromEnvironment(
  'FEATHERLOG_DISTRIBUTION',
  defaultValue: 'github',
);

/// True for the Google Play build.
const bool kIsPlayBuild = kDistribution == 'play';

/// Whether the in-app "check GitHub for a newer release" feature is available.
///
/// **Off for the Play build.** Google Play's Device & Network Abuse policy
/// forbids steering users to update through any mechanism other than Play, and
/// Play handles updates itself — so the whole GitHub update-check feature is
/// compiled out of the Play bundle. The GitHub/Obtainium build keeps it.
const bool kInAppUpdateCheck = !kIsPlayBuild;
