import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// An editorial "kicker" section header: a short accent bar followed by a
/// small-caps, letter-spaced label. Gives each section a clear, magazine-like
/// identity instead of a plain title (the Almanac design language).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;

  /// Optional trailing widget (e.g. a "see all" action), right-aligned.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}
