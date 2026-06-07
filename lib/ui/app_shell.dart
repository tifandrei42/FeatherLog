import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_entry_sheet.dart';
import 'add_measurement_sheet.dart';
import 'body_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';
import 'trends_screen.dart';
import 'widgets/shiny_button.dart';

/// The selected bottom-nav tab. Exposed as a provider so any screen can switch
/// tabs (e.g. Today's "View full trend" jumps to the Trends tab).
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(
  SelectedTabNotifier.new,
);

/// The app's top-level 4-tab shell for the "Almanac" redesign:
/// Today · Trends · Body · Settings, with a contextual logging FAB. Replaces
/// the old single-screen HomeScreen.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(selectedTabProvider);

    // The FAB is contextual: the Body tab logs a measurement, Today/Trends log
    // a weight, and Settings has no FAB.
    Widget? fab;
    if (index == 2) {
      fab = ShinyButton(
        label: 'Add measurement',
        icon: Icons.straighten,
        onPressed: () => showAddMeasurementSheet(context),
      );
    } else if (index != 3) {
      fab = ShinyButton(
        label: 'Log weight',
        icon: Icons.add,
        onPressed: () => showAddEntrySheet(context),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          TodayScreen(),
          TrendsScreen(),
          BodyScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).select(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.straighten),
            selectedIcon: Icon(Icons.straighten),
            label: 'Body',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
