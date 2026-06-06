import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/data_providers.dart';
import 'ui/home_screen.dart';
import 'ui/theme/app_theme.dart';

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

    return MaterialApp(
      title: 'FeatherLog',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
