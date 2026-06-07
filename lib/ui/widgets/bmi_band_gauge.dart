import 'package:flutter/material.dart';

import '../../domain/bmi.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A horizontal BMI scale (aktiBMI-style): the four WHO bands as a coloured
/// strip from BMI [_min] to [_max], with a marker at the current [bmi]. Colour
/// is supplemented by the value/category text in the parent, so meaning never
/// rests on colour alone.
class BmiBandGauge extends StatelessWidget {
  const BmiBandGauge({super.key, required this.bmi});

  final double bmi;

  static const double _min = 15;
  static const double _max = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<FeatherPalette>();
    Color bandColor(BmiCategory c) =>
        palette?.forBmiCategory(c) ?? theme.colorScheme.primary;

    // Band widths proportional to their BMI spans over [15, 40]:
    // under 15–18.5 (3.5), normal 18.5–25 (6.5), over 25–30 (5), obese 30–40 (10)
    // → ×2 as integer flex.
    final fraction = ((bmi - _min) / (_max - _min)).clamp(0.0, 1.0);
    final markerX = fraction * 2 - 1; // map 0..1 → -1..1 for Alignment

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: _seg(bandColor(BmiCategory.underweight)),
                      ),
                      Expanded(
                        flex: 13,
                        child: _seg(bandColor(BmiCategory.normal)),
                      ),
                      Expanded(
                        flex: 10,
                        child: _seg(bandColor(BmiCategory.overweight)),
                      ),
                      Expanded(
                        flex: 20,
                        child: _seg(bandColor(BmiCategory.obeseClassI)),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment(markerX, 0),
                child: Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        DefaultTextStyle(
          style:
              theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(),
          child: Row(
            children: const [
              Expanded(flex: 7, child: _Label('Under')),
              Expanded(flex: 13, child: _Label('Normal')),
              Expanded(flex: 10, child: _Label('Over')),
              Expanded(flex: 20, child: _Label('Obese')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seg(Color color) => Container(height: 10, color: color);
}

/// A band caption that shrinks rather than overflowing its (narrow) segment.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: FittedBox(fit: BoxFit.scaleDown, child: Text(text)),
  );
}
