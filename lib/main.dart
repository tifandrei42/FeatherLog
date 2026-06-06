import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/data_providers.dart';
import 'ui/home_screen.dart';

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

    const seed = Color(0xFF3A7CA5); // calm blue — "feather" light.
    return MaterialApp(
      title: 'FeatherLog',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
