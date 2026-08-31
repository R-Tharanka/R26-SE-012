import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'analysis_ui.dart';
import 'ai_errors.dart';
import 'ai_pest_service.dart';
import 'pest_analysis.dart';
import 'pest_treatment_engine.dart';
import 'remediation_engine.dart' show Market;

/// Captures a pepper-plant photo, runs AI pest vision, then shows IPM +
/// export-aware treatment from the deterministic [PestTreatmentEngine].
class PestAnalysisScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Future<PestAnalysis>? prefetch;
  const PestAnalysisScreen({
    super.key,
    required this.imageBytes,
    this.prefetch,
  });

  @override
  State<PestAnalysisScreen> createState() => _PestAnalysisScreenState();
}

class _PestAnalysisScreenState extends State<PestAnalysisScreen> {
  final _service = AiPestService();
  late Future<PestAnalysis>? _pending = widget.prefetch;
  bool _loading = true;
  PestAnalysis? _result;
  String? _error;
  Market _market = Market.eu;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await (_pending ?? _service.analyze(widget.imageBytes));
      _pending = null;
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    } catch (e, st) {
      logAiError('pest-analysis', e, st);
      if (!mounted) return;
      setState(() {
        _error = friendlyAiMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnalysisScaffold(
      imageBytes: widget.imageBytes,
      title: 'Pest analysis',
      titleIcon: IconlyBold.scan,
      children: _body(),
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return const [LoadingView(message: 'Inspecting for pests with AI…')];
    }
    if (_error != null) {
      return [ErrorView(message: _error!, onRetry: _run)];
    }
    return _result == null ? const [] : _resultBody(_result!);
  }

  List<Widget> _resultBody(PestAnalysis r) {
    if (!r.isPepperPlant) {
      return [
        RetakeView(
          title: "This doesn't look like a pepper plant",
          message: r.summary.isNotEmpty
              ? r.summary
              : 'Get closer to the leaf/stem/berry in good light and retry.',
          onRetake: () => Navigator.of(context).pop(),
        ),
      ];
    }

    final plan = PestTreatmentEngine.forAnalysis(r, _market);
    final accent = r.healthy ? kBrand : bandColor(r.severityBand);

    return [
      Row(children: [
        Icon(r.healthy ? IconlyBold.shield_done : IconlyBold.danger,
            color: accent, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.healthy ? 'No pests found' : r.pestType,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
              if (r.summary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(r.summary,
                      style: TextStyle(color: kTextSub, height: 1.35)),
                ),
            ],
          ),
        ),
      ]),

      const SizedBox(height: 18),
      StatTile(
        icon: IconlyBold.chart,
        label: 'Severity',
        color: accent,
        value: r.healthy
            ? const Text('—',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: kBrand))
            : CountUp(r.severityPercentage,
                suffix: '%',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: accent)),
        sub: r.severityBand.toUpperCase(),
      ),

      // Economic Threshold badge — the key pest decision.
      _thresholdBadge(plan.aboveThreshold),

      MarketRow(dropdown: _marketDropdown()),

      SectionCard(
        icon: IconlyBold.shield_done,
        title: 'Recommended action (IPM)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.action,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: kText, height: 1.35)),
            const SizedBox(height: 12),
            for (final o in plan.options)
              OptionTile(
                name: o.name,
                mix: o.mix,
                method: o.method,
                allowed: o.allowedInMarket,
                restriction: o.restriction,
                phiNote: o.phi,
                isChemical: o.isChemical,
              ),
            for (final w in plan.warnings) _warning(w),
          ],
        ),
      ),

      if (plan.note.isNotEmpty)
        InfoCard(
          icon: IconlyBold.bag,
          color: const Color(0xFF3B82F6),
          text: plan.note,
        ),

      const InfoCard(
        icon: IconlyBold.info_circle,
        color: Color(0xFF64748B),
        text:
            'AI estimate from one photo. Confirm the pest, economic threshold, '
            'exact dose, MRL and pre-harvest interval with your local agri '
            'authority before any chemical use.',
      ),

      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(IconlyLight.camera, size: 18),
        label: const Text('Take another photo'),
      ),
    ];
  }

  Widget _thresholdBadge(bool above) {
    final color = above ? const Color(0xFFFB8C00) : kBrand;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(above ? IconlyBold.danger : IconlyBold.show, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            above
                ? 'Above treatment threshold'
                : 'Below treatment threshold — monitor only',
            style: TextStyle(fontWeight: FontWeight.w700, color: kText),
          ),
        ),
      ]),
    );
  }

  Widget _marketDropdown() => DropdownButton<Market>(
        value: _market,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        style: TextStyle(color: kText, fontWeight: FontWeight.w600),
        icon: Icon(IconlyLight.arrow_down, size: 16, color: kText),
        onChanged: (m) => setState(() => _market = m ?? _market),
        items: [
          for (final m in Market.values)
            DropdownMenuItem(value: m, child: Text(m.label)),
        ],
      );

  Widget _warning(String w) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(IconlyBold.danger, size: 15, color: Color(0xFFB26A00)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(w,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB26A00), height: 1.35))),
        ]),
      );
}
