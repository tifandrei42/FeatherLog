import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/data_providers.dart';
import 'ui/app_shell.dart';
import 'ui/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/tokens.dart';

void main() {
  runApp(const ProviderScope(child: FeatherLogApp()));
}

class FeatherLogApp extends ConsumerWidget {
  const FeatherLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme mode follows the saved setting once available; defaults to system.
    // 'amoled' is a dark variant (true black), so it maps to ThemeMode.dark and
    // swaps the dark theme below.
    final settings = ref.watch(settingsProvider).value;
    final themeChoice = settings?.theme ?? 'system';
    final isAmoled = themeChoice == 'amoled';
    final themeMode = switch (themeChoice) {
      'light' => ThemeMode.light,
      'dark' || 'amoled' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final paletteId = settings?.palette ?? featherPalettes.first.id;
    final wantsDynamic = paletteId == dynamicPaletteId;
    final palette = paletteById(paletteId); // 'dynamic' falls back to default

    // DynamicColorBuilder supplies wallpaper-derived schemes on Android 12+
    // (null elsewhere). We only use them when the user picked the Dynamic
    // palette AND they're actually available — otherwise the curated palette
    // applies, so behaviour is unchanged for everyone who hasn't opted in.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic =
            wantsDynamic && lightDynamic != null && darkDynamic != null;

        final lightTheme = useDynamic
            ? AppTheme.fromDynamic(lightDynamic.harmonized())
            : AppTheme.light(palette);
        final darkTheme = useDynamic
            ? AppTheme.fromDynamic(darkDynamic.harmonized(), amoled: isAmoled)
            : (isAmoled ? AppTheme.amoled(palette) : AppTheme.dark(palette));

        return MaterialApp(
          title: 'FeatherLog',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const _RootGate(),
        );
      },
    );
  }
}

/// Chooses the first screen: onboarding on a true first run, otherwise the app.
///
/// "First run" = onboarding not yet completed AND no entries logged. The second
/// clause matters because the `onboardingDone` flag defaults to false: a user
/// who already has history (e.g. after the v7 update) is treated as onboarded
/// and never sees the flow. Both providers are awaited first to avoid a flash
/// of the wrong screen.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final entriesAsync = ref.watch(entriesProvider);

    if (settingsAsync.isLoading || entriesAsync.isLoading) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // On a read error, fail open to the app — its screens surface their own
    // error states. Never show first-run onboarding to a returning user just
    // because their data couldn't be read this instant; doing so would also let
    // a "skip" overwrite their (intact but momentarily unreadable) settings.
    if (settingsAsync.hasError || entriesAsync.hasError) {
      return const AppShell();
    }

    final onboardingDone = settingsAsync.value?.onboardingDone ?? false;
    final hasEntries = (entriesAsync.value ?? const []).isNotEmpty;
    final showOnboarding = !onboardingDone && !hasEntries;

    return showOnboarding ? const OnboardingScreen() : const AppShell();
  }
}
