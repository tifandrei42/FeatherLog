import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/age.dart';
import '../domain/bmi.dart';
import '../domain/consistency.dart';
import '../domain/daily.dart';
import '../domain/milestones.dart';
import '../domain/stats.dart';
import '../domain/units.dart';
import 'database.dart';

/// Builds a shareable "doctor export" PDF: a calm, professional health report
/// covering the weight/BMI trend, key statistics and the underlying entries over
/// a chosen period (issue #52).
///
/// Local-only — this produces PDF bytes and never touches the network. The
/// trend is drawn as **vector primitives** (`pw.Chart`), not a screenshot of the
/// on-screen fl_chart, so it stays crisp at any zoom and needs no widget render.
///
/// Generation is pure: all inputs (including [generatedAt]) are passed in, so it
/// runs deterministically off-device and is unit-testable without a database.
/// Uses the built-in Helvetica family (no bundled fonts) so it works in tests
/// and stays small.
class PdfReportService {
  const PdfReportService();

  /// FeatherLog periwinkle, used sparingly for the trend line and accents.
  static const PdfColor _brand = PdfColor.fromInt(0xFF4F6BED);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _rule = PdfColor.fromInt(0xFFE5E7EB);

  /// Renders the report to PDF bytes.
  ///
  /// [entries] are the raw readings (any order); [measurements] the body
  /// measurements; [range] selects how far back the report looks (the entries
  /// table and trend are limited to it, while "total change" still spans all of
  /// history). Empty/sparse data is handled gracefully.
  Future<Uint8List> build({
    required Profile? profile,
    required Setting? settings,
    required List<WeightEntry> entries,
    required ChartRange range,
    required DateTime generatedAt,
    List<BodyMeasurement> measurements = const [],
  }) async {
    final weightUnit = settings?.weightUnit == 'lb'
        ? WeightUnit.lb
        : WeightUnit.kg;
    final lengthUnit = settings?.lengthUnit == 'in'
        ? LengthUnit.inch
        : LengthUnit.cm;
    final wLabel = weightUnit == WeightUnit.lb ? 'lb' : 'kg';
    double toW(double kg) => weightFromKg(kg, weightUnit);

    final readings = [
      for (final e in entries)
        Reading(measuredAt: e.measuredAt, weightKg: e.weightKg),
    ];
    final allDaily = dailyAverages(readings);
    final periodDaily = filterByRange(allDaily, range);

    // Cutoff for limiting the raw-entries table to the selected period.
    DateTime? cutoff;
    if (range.days != null && allDaily.isNotEmpty) {
      cutoff = allDaily.last.day.subtract(Duration(days: range.days! - 1));
    }
    final periodEntries = [
      for (final e in entries)
        if (cutoff == null || !_dayOf(e.measuredAt).isBefore(cutoff)) e,
    ]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    final df = DateFormat('y-MM-dd');
    final dfTime = DateFormat('y-MM-dd HH:mm');

    final doc = pw.Document(
      title: 'FeatherLog Health Report',
      author: 'FeatherLog',
      creator: 'FeatherLog',
    );

    final baseStyle = pw.TextStyle(fontSize: 10, color: PdfColors.black);
    final theme = pw.ThemeData.withFont().copyWith(defaultTextStyle: baseStyle);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 44),
        header: (context) => _runningHeader(context, generatedAt, df),
        footer: _footer,
        build: (context) {
          if (entries.isEmpty) {
            return [
              _title(generatedAt, range, df),
              pw.SizedBox(height: 24),
              pw.Text(
                'No measurements have been recorded yet.',
                style: pw.TextStyle(
                  color: _muted,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ];
          }

          return [
            _title(generatedAt, range, df),
            pw.SizedBox(height: 16),
            _section('Summary'),
            _summaryTable(
              profile: profile,
              allDaily: allDaily,
              generatedAt: generatedAt,
              toW: toW,
              wLabel: wLabel,
              lengthUnit: lengthUnit,
            ),
            pw.SizedBox(height: 18),
            _section('Weight trend'),
            _trendChart(periodDaily, toW, wLabel),
            pw.SizedBox(height: 18),
            _section('Statistics'),
            _statsTable(
              periodDaily: periodDaily,
              allDaily: allDaily,
              range: range,
              toW: toW,
              wLabel: wLabel,
            ),
            ..._compositionSection(entries),
            ..._measurementsSection(measurements, lengthUnit, generatedAt),
            ..._consistencySection(allDaily, generatedAt),
            ..._achievementsSection(allDaily, profile, toW, wLabel, df),
            pw.SizedBox(height: 18),
            _section('Entries (${_rangeLabel(range)})'),
            _entriesTable(periodEntries, profile, toW, wLabel, dfTime),
            pw.SizedBox(height: 18),
            _disclaimer(profile, generatedAt),
          ];
        },
      ),
    );

    return doc.save();
  }

  // ---- Layout helpers -------------------------------------------------------

  pw.Widget _title(DateTime at, ChartRange range, DateFormat df) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'FeatherLog Health Report',
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'Period: ${_rangeLabel(range)}  ·  Generated ${df.format(at)}',
        style: pw.TextStyle(color: _muted, fontSize: 10),
      ),
    ],
  );

  pw.Widget _section(String text) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 6),
    padding: const pw.EdgeInsets.only(bottom: 3),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 1)),
    ),
    child: pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _brand,
        letterSpacing: 0.6,
      ),
    ),
  );

  pw.Widget _runningHeader(pw.Context context, DateTime at, DateFormat df) {
    if (context.pageNumber == 1) return pw.SizedBox();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        'FeatherLog Health Report · ${df.format(at)}',
        style: pw.TextStyle(color: _muted, fontSize: 8),
      ),
    );
  }

  pw.Widget _footer(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.only(top: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.5)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Not medical advice - BMI is a screening tool, not a diagnosis.',
          style: pw.TextStyle(color: _muted, fontSize: 8),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(color: _muted, fontSize: 8),
        ),
      ],
    ),
  );

  /// A clean key/value table with no outer borders (for summary-style blocks).
  pw.Widget _kvTable(List<List<String>> rows) => pw.Table(
    columnWidths: const {0: pw.FixedColumnWidth(150), 1: pw.FlexColumnWidth()},
    children: [
      for (final r in rows)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                r[0],
                style: pw.TextStyle(color: _muted, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(r[1], style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
    ],
  );

  // ---- Sections -------------------------------------------------------------

  pw.Widget _summaryTable({
    required Profile? profile,
    required List<DailyWeight> allDaily,
    required DateTime generatedAt,
    required double Function(double) toW,
    required String wLabel,
    required LengthUnit lengthUnit,
  }) {
    final rows = <List<String>>[];
    final height = profile?.heightCm;

    if (height != null) {
      final v = lengthFromCm(height, lengthUnit);
      final lLabel = lengthUnit == LengthUnit.inch ? 'in' : 'cm';
      rows.add([
        'Height',
        '${v.toStringAsFixed(lengthUnit == LengthUnit.inch ? 1 : 0)} $lLabel',
      ]);
    }
    if (profile?.sex != null && profile!.sex!.isNotEmpty) {
      rows.add(['Sex', profile.sex!]);
    }
    final age = ageInYears(profile?.birthDate, asOf: generatedAt);
    if (age != null) rows.add(['Age', '$age']);
    if (profile?.goalWeightKg != null) {
      rows.add([
        'Goal weight',
        '${toW(profile!.goalWeightKg!).toStringAsFixed(1)} $wLabel',
      ]);
    }

    if (allDaily.isNotEmpty) {
      final latest = allDaily.last;
      rows.add([
        'Latest weight',
        '${toW(latest.weightKg).toStringAsFixed(1)} $wLabel'
            '  (${DateFormat('y-MM-dd').format(latest.day)})',
      ]);
      if (height != null && height > 0) {
        final bmi = calculateBmi(weightKg: latest.weightKg, heightCm: height);
        final applies = adultBmiBandsApply(
          profile?.birthDate,
          asOf: generatedAt,
        );
        final cat = applies
            ? bmiCategoryFor(bmi).label
            : 'adult bands N/A (under 20)';
        rows.add(['Latest BMI', '${bmi.toStringAsFixed(1)}  ($cat)']);
      }
    }

    return _kvTable(rows);
  }

  pw.Widget _statsTable({
    required List<DailyWeight> periodDaily,
    required List<DailyWeight> allDaily,
    required ChartRange range,
    required double Function(double) toW,
    required String wLabel,
  }) {
    String d(double? kg) =>
        kg == null ? '-' : '${toW(kg).toStringAsFixed(1)} $wLabel';
    // Signed change reads more naturally for a delta.
    String signed(double? kg) {
      if (kg == null) return '-';
      final v = toW(kg);
      final sign = v > 0 ? '+' : '';
      return '$sign${v.toStringAsFixed(1)} $wLabel';
    }

    final rate = ratePerWeek(periodDaily);
    final rows = <List<String>>[
      ['Total change (all time)', signed(totalChange(allDaily))],
      // A separate period-change row only adds information when the period is
      // narrower than all of history.
      if (range.days != null)
        [
          'Change (${_rangeLabel(range)})',
          signed(periodChange(periodDaily, range.days!)),
        ],
      [
        'Rate',
        rate == null
            ? '-'
            : '${rate >= 0 ? '+' : ''}${toW(rate).toStringAsFixed(2)} $wLabel/week',
      ],
      ['Lowest (${_rangeLabel(range)})', d(minWeight(periodDaily))],
      ['Highest (${_rangeLabel(range)})', d(maxWeight(periodDaily))],
      ['Average (${_rangeLabel(range)})', d(averageWeight(periodDaily))],
    ];
    return _kvTable(rows);
  }

  List<pw.Widget> _compositionSection(List<WeightEntry> entries) {
    // Latest non-null value for each composition field across all entries.
    final byTime = [...entries]
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    double? latest(double? Function(WeightEntry) get) {
      for (final e in byTime) {
        final v = get(e);
        if (v != null) return v;
      }
      return null;
    }

    final fat = latest((e) => e.bodyFatPct);
    final muscle = latest((e) => e.musclePct);
    final water = latest((e) => e.waterPct);
    if (fat == null && muscle == null && water == null) return const [];

    final rows = <List<String>>[
      if (fat != null) ['Body fat', '${fat.toStringAsFixed(1)} %'],
      if (muscle != null) ['Muscle', '${muscle.toStringAsFixed(1)} %'],
      if (water != null) ['Water', '${water.toStringAsFixed(1)} %'],
    ];
    return [
      pw.SizedBox(height: 18),
      _section('Body composition (latest)'),
      _kvTable(rows),
    ];
  }

  List<pw.Widget> _measurementsSection(
    List<BodyMeasurement> measurements,
    LengthUnit unit,
    DateTime generatedAt,
  ) {
    if (measurements.isEmpty) return const [];
    final lLabel = unit == LengthUnit.inch ? 'in' : 'cm';
    // Latest reading per type.
    final latestByType = <String, BodyMeasurement>{};
    for (final m in measurements) {
      final cur = latestByType[m.type];
      if (cur == null || m.measuredAt.isAfter(cur.measuredAt)) {
        latestByType[m.type] = m;
      }
    }
    final types = latestByType.keys.toList()..sort();
    final rows = [
      for (final t in types)
        [
          _capitalize(t),
          '${lengthFromCm(latestByType[t]!.valueCm, unit).toStringAsFixed(1)} '
              '$lLabel',
        ],
    ];
    return [
      pw.SizedBox(height: 18),
      _section('Body measurements (latest)'),
      _kvTable(rows),
    ];
  }

  List<pw.Widget> _consistencySection(
    List<DailyWeight> allDaily,
    DateTime generatedAt,
  ) {
    if (allDaily.isEmpty) return const [];
    final rows = <List<String>>[
      ['Current streak', '${currentStreak(allDaily, today: generatedAt)} days'],
      ['Longest streak', '${longestStreak(allDaily)} days'],
      [
        'Days logged (last 30)',
        '${daysLoggedIn(allDaily, today: generatedAt)} / 30',
      ],
    ];
    return [pw.SizedBox(height: 18), _section('Consistency'), _kvTable(rows)];
  }

  List<pw.Widget> _achievementsSection(
    List<DailyWeight> allDaily,
    Profile? profile,
    double Function(double) toW,
    String wLabel,
    DateFormat df,
  ) {
    final milestones = detectMilestones(
      allDaily,
      goalKg: profile?.goalWeightKg,
    );
    if (milestones.isEmpty) return const [];
    // Show the most recent few, newest first.
    final recent = milestones.reversed.take(6).toList();
    final rows = [
      for (final m in recent) [df.format(m.day), m.label],
    ];
    return [pw.SizedBox(height: 18), _section('Achievements'), _kvTable(rows)];
  }

  pw.Widget _entriesTable(
    List<WeightEntry> entries,
    Profile? profile,
    double Function(double) toW,
    String wLabel,
    DateFormat dfTime,
  ) {
    if (entries.isEmpty) {
      return pw.Text(
        'No entries in this period.',
        style: pw.TextStyle(color: _muted, fontStyle: pw.FontStyle.italic),
      );
    }
    final height = profile?.heightCm;
    final data = [
      for (final e in entries)
        [
          dfTime.format(e.measuredAt),
          toW(e.weightKg).toStringAsFixed(1),
          (height != null && height > 0)
              ? calculateBmi(
                  weightKg: e.weightKg,
                  heightCm: height,
                ).toStringAsFixed(1)
              : '-',
          _truncate(e.note ?? '', 42),
        ],
    ];
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Weight ($wLabel)', 'BMI', 'Note'],
      data: data,
      border: pw.TableBorder.all(color: _rule, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _brand),
      cellStyle: const pw.TextStyle(fontSize: 9),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
      ),
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
      },
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(3.4),
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    );
  }

  pw.Widget _disclaimer(Profile? profile, DateTime generatedAt) {
    final notApplicable = !adultBmiBandsApply(
      profile?.birthDate,
      asOf: generatedAt,
    );
    final lines = <String>[
      'This report was generated by FeatherLog from self-recorded '
          'measurements. BMI is a population-level screening tool, not a '
          'diagnosis - interpret it with a healthcare professional.',
      if (notApplicable)
        'The recorded age is under 20, so the adult WHO BMI bands do not apply; '
            'BMI for children and teens must be read against age/sex '
            'percentiles, which this report does not compute.',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF3F4F6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                l,
                style: pw.TextStyle(color: _muted, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  /// The trend, drawn with pdf vector primitives. Falls back to a note when
  /// there aren't at least two points to connect.
  pw.Widget _trendChart(
    List<DailyWeight> series,
    double Function(double) toW,
    String wLabel,
  ) {
    if (series.length < 2) {
      return pw.Text(
        'Not enough data to plot a trend for this period.',
        style: pw.TextStyle(color: _muted, fontStyle: pw.FontStyle.italic),
      );
    }

    final x0 = series.first.day;
    final points = [
      for (final d in series)
        pw.PointChartValue(
          d.day.difference(x0).inDays.toDouble(),
          toW(d.weightKg),
        ),
    ];

    final xs = points.map((p) => p.x).toList();
    final ys = points.map((p) => p.y).toList();
    final maxX = xs.reduce(math.max);
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    // Guard a flat series so the axis has a visible span.
    if ((maxY - minY).abs() < 0.5) {
      minY -= 1;
      maxY += 1;
    }
    final pad = (maxY - minY) * 0.12;
    minY -= pad;
    maxY += pad;

    final yTicks = [for (var i = 0; i <= 4; i++) minY + (maxY - minY) * i / 4];
    final xTickCount = math.min(5, points.length);
    final xTicks = [
      for (var i = 0; i < xTickCount; i++)
        xTickCount == 1 ? 0.0 : maxX * i / (xTickCount - 1),
    ];
    final xLabelFmt = DateFormat('MMM d');

    return pw.Container(
      height: 190,
      padding: const pw.EdgeInsets.only(top: 4, right: 8),
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis(
            xTicks,
            format: (v) => xLabelFmt.format(x0.add(Duration(days: v.round()))),
            divisions: true,
            divisionsColor: _rule,
            textStyle: pw.TextStyle(fontSize: 7, color: _muted),
          ),
          yAxis: pw.FixedAxis(
            yTicks,
            format: (v) => '${v.toStringAsFixed(1)} $wLabel',
            divisions: true,
            divisionsColor: _rule,
            textStyle: pw.TextStyle(fontSize: 7, color: _muted),
          ),
        ),
        datasets: [
          pw.LineDataSet(
            data: points,
            drawPoints: points.length <= 31,
            pointSize: 1.5,
            pointColor: _brand,
            color: _brand,
            lineWidth: 1.4,
            isCurved: false,
          ),
        ],
      ),
    );
  }

  // ---- Small utilities ------------------------------------------------------

  static String _rangeLabel(ChartRange range) => switch (range) {
    ChartRange.week => 'last 7 days',
    ChartRange.month => 'last 30 days',
    ChartRange.threeMonths => 'last 3 months',
    ChartRange.year => 'last year',
    ChartRange.all => 'all time',
  };

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max - 3)}...';
}
