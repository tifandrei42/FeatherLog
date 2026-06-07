import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/data_providers.dart';
import 'ui/app_shell.dart';
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
      home: const AppShell(),
    );
  }
}
