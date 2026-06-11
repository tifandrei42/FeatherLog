import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/units.dart';
import '../providers/data_providers.dart';
import '../providers/database_provider.dart';
import 'theme/tokens.dart';
import 'widgets/shiny_button.dart';

/// First-run onboarding: three airy, fully skippable steps — welcome, "about
/// you" (units + height), and an optional goal (US-1.x, UI_DESIGN.md §8.6).
///
/// Design contract (issue #65): each step asks one thing, every step is
/// skippable, and logging works immediately even if everything is skipped.
/// Whatever the user does enter (units, height, goal, birth year, sex) is
/// persisted; finishing or skipping sets `onboardingDone` so this shows only on
/// first run. It's also pushed from Settings ("Run setup again"), in which case
/// it pops on completion instead of relying on the root gate.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  late bool _metric;
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();
  final _birthYearController = TextEditingController();
  String? _sex;
  bool _saving = false;

  static const _stepCount = 3;

  @override
  void initState() {
    super.initState();
    // Pre-fill from any existing data so "Run setup again" isn't a blank slate.
    final settings = ref.read(settingsProvider).value;
    final profile = ref.read(profileProvider).value;
    _metric = (settings?.weightUnit ?? 'kg') != 'lb';

    final lengthUnit = _metric ? LengthUnit.cm : LengthUnit.inch;
    final weightUnit = _metric ? WeightUnit.kg : WeightUnit.lb;
    if (profile?.heightCm != null) {
      _heightController.text = _fmt(
        lengthFromCm(profile!.heightCm!, lengthUnit),
        decimals: _metric ? 0 : 1,
      );
    }
    if (profile?.goalWeightKg != null) {
      _goalController.text = _fmt(
        weightFromKg(profile!.goalWeightKg!, weightUnit),
        decimals: 1,
      );
    }
    if (profile?.birthDate != null) {
      _birthYearController.text = '${profile!.birthDate!.year}';
    }
    _sex = profile?.sex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  LengthUnit get _lengthUnit => _metric ? LengthUnit.cm : LengthUnit.inch;
  WeightUnit get _weightUnit => _metric ? WeightUnit.kg : WeightUnit.lb;

  static String _fmt(double v, {required int decimals}) =>
      v.toStringAsFixed(decimals);

  static double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _setMetric(bool metric) {
    if (metric == _metric) return;
    // Convert any already-typed values so switching units doesn't change them.
    final h = _parse(_heightController);
    final g = _parse(_goalController);
    final fromLen = _metric ? LengthUnit.cm : LengthUnit.inch;
    final toLen = metric ? LengthUnit.cm : LengthUnit.inch;
    final fromW = _metric ? WeightUnit.kg : WeightUnit.lb;
    final toW = metric ? WeightUnit.kg : WeightUnit.lb;
    if (h != null) {
      _heightController.text = _fmt(
        lengthFromCm(lengthToCm(h, fromLen), toLen),
        decimals: metric ? 0 : 1,
      );
    }
    if (g != null) {
      _goalController.text = _fmt(
        weightFromKg(weightToKg(g, fromW), toW),
        decimals: 1,
      );
    }
    setState(() => _metric = metric);
  }

  void _next() {
    if (_step < _stepCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Persists whatever was entered, marks onboarding done, and leaves. Used by
  /// both "finish" and every "skip" — skipping just means some fields are blank.
  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    await db.settingsDao.updateWeightUnit(_metric ? 'kg' : 'lb');
    await db.settingsDao.updateLengthUnit(_metric ? 'cm' : 'in');

    final height = _parse(_heightController);
    if (height != null) {
      await db.profileDao.updateHeight(lengthToCm(height, _lengthUnit));
    }
    final goal = _parse(_goalController);
    if (goal != null) {
      await db.profileDao.updateGoalWeight(weightToKg(goal, _weightUnit));
    }
    final birthYear = int.tryParse(_birthYearController.text.trim());
    if (birthYear != null &&
        birthYear > 1900 &&
        birthYear <= DateTime.now().year) {
      await db.profileDao.updateBirthDate(DateTime(birthYear, 1, 1));
    }
    if (_sex != null) await db.profileDao.updateSex(_sex);

    await db.settingsDao.setOnboardingDone(true);

    if (!mounted) return;
    // Pushed from Settings → pop back; first-run (home) → the root gate swaps
    // to the app shell when onboardingDone flips, so there's nothing to pop.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              step: _step,
              stepCount: _stepCount,
              onBack: _step > 0 ? _back : null,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [_welcomeStep(), _aboutStep(), _goalStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Step 1: welcome -----------------------------------------------------

  Widget _welcomeStep() {
    final theme = Theme.of(context);
    return _StepScaffold(
      primaryLabel: 'Get started',
      onPrimary: _next,
      skipLabel: 'Skip — just let me log',
      onSkip: _finish,
      saving: _saving,
      children: [
        const SizedBox(height: Spacing.xl),
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.65),
                ],
              ),
            ),
            child: Icon(
              Icons.spa_outlined,
              size: 48,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Text(
          'Travel light.',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Track your weight calmly, privately, and entirely on your device.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        _PrivacyChip(),
      ],
    );
  }

  // ---- Step 2: about you ---------------------------------------------------

  Widget _aboutStep() {
    final theme = Theme.of(context);
    return _StepScaffold(
      primaryLabel: 'Continue',
      onPrimary: _next,
      skipLabel: 'Skip for now',
      onSkip: _finish,
      saving: _saving,
      children: [
        Text(
          'About you',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Your height lets us show BMI from your very first log.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text('Units', style: theme.textTheme.labelLarge),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('kg · cm')),
              ButtonSegment(value: false, label: Text('lb · in')),
            ],
            selected: {_metric},
            onSelectionChanged: (s) => _setMetric(s.first),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: 'Height',
            suffixText: _metric ? 'cm' : 'in',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'Birth year & sex (optional — refines BMI context)',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _sex,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Prefer not to say'),
                  ),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                ],
                onChanged: (v) => setState(() => _sex = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Step 3: goal --------------------------------------------------------

  Widget _goalStep() {
    final theme = Theme.of(context);
    return _StepScaffold(
      primaryLabel: 'Start logging',
      onPrimary: _finish,
      skipLabel: 'No goal yet',
      onSkip: _finish,
      saving: _saving,
      children: [
        Text(
          'A direction, not a deadline',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Set a goal to unlock the progress ring. You can change or remove it '
          'anytime, and gain goals are first-class too.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        TextField(
          controller: _goalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: 'Goal weight',
            suffixText: _metric ? 'kg' : 'lb',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// Progress dots + an optional back button, shown above every step.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.stepCount,
    required this.onBack,
  });

  final int step;
  final int stepCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                  ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < stepCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == step ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == step
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Shared per-step layout: scrollable content, a primary pill button, and a
/// subtle skip link. Keeps all three steps visually identical in structure.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    required this.skipLabel,
    required this.onSkip,
    required this.saving,
  });

  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String skipLabel;
  final VoidCallback onSkip;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          // _finish guards against double-submit internally, so the button stays
          // tappable; we just ignore taps while a save is in flight.
          ShinyButton(
            label: primaryLabel,
            icon: Icons.arrow_forward,
            expanded: true,
            onPressed: onPrimary,
          ),
          TextButton(onPressed: saving ? null : onSkip, child: Text(skipLabel)),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'No account. No cloud. No ads.',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
