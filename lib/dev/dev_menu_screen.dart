import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import 'dev_seed.dart';

/// Dev-only tools screen. Only reachable when `kDebugMode` is true (the entry
/// point in HomeScreen is gated), so it is tree-shaken out of release builds.
class DevMenuScreen extends ConsumerWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer tools')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Seed realistic test data'),
            subtitle: const Text(
              'Deletes all entries and inserts a fake down–up–down series.',
            ),
            onTap: () => _confirmAndSeed(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSeed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed fake data?'),
        content: const Text(
          'This deletes all existing entries and seeds fake data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete & seed'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await seedRealisticData(ref.read(databaseProvider));
    messenger.showSnackBar(
      const SnackBar(content: Text('Seeded realistic test data')),
    );
  }
}
