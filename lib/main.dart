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
    final settings = ref.watch(settingsProvider).value;
    final themeMode = switch (settings?.theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final palette = paletteById(settings?.palette);
    return MaterialApp(
      title: 'FeatherLog',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(palette),
      darkTheme: AppTheme.dark(palette),
      home: const _RootGate(),
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

    final onboardingDone = settingsAsync.value?.onboardingDone ?? false;
    final hasEntries = (entriesAsync.value ?? const []).isNotEmpty;
    final showOnboarding = !onboardingDone && !hasEntries;

    return showOnboarding ? const OnboardingScreen() : const AppShell();
  }
}
