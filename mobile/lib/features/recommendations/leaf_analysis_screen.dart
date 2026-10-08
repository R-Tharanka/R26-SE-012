import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/class_labels.dart';
import 'analysis_ui.dart';
import 'ai_errors.dart';
import 'ai_leaf_service.dart';
import 'leaf_analysis.dart';

/// Runs an AI leaf analysis on a captured photo and shows the result.
///
/// [prefetch] lets the scanner start the analysis in the background the moment
/// a problem is detected, so the result is often ready by the time the user
/// opens this screen. If null (or after a retry), it runs its own call.
class LeafAnalysisScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Future<LeafAnalysis>? prefetch;
  const LeafAnalysisScreen({
    super.key,
    required this.imageBytes,
    this.prefetch,
  });

  @override
  State<LeafAnalysisScreen> createState() => _LeafAnalysisScreenState();
}

class _LeafAnalysisScreenState extends State<LeafAnalysisScreen> {
  final _service = AiLeafService();
  late Future<LeafAnalysis>? _pending = widget.prefetch;
  bool _loading = true;
  LeafAnalysis? _result;
  String? _error;

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
      _pending =
          null; // a retry re-calls the service instead of the dead future
      if (!mounted) return;
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    } catch (e, st) {
      logAiError('leaf-analysis', e, st);
      if (!mounted) return;
      setState(() {
        _error = friendlyAiMessage(e, AppLocalizations.of(context));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnalysisScaffold(
      imageBytes: widget.imageBytes,
      title: AppLocalizations.of(context).leafAnalysisTitle,
      titleIcon: IconlyBold.activity,
      children: _body(),
    );
  }

  List<Widget> _body() {
    final t = AppLocalizations.of(context);
    if (_loading) {
      return [LoadingView(message: t.analysingLeaf)];
    }
    if (_error != null) {
      return [ErrorView(message: _error!, onRetry: _run)];
    }
    return _result == null ? const [] : _resultBody(_result!);
  }

  List<Widget> _resultBody(LeafAnalysis r) {
    final t = AppLocalizations.of(context);
    if (!r.isPepperLeaf) {
      return [
        RetakeView(
          title: t.notPepperLeaf,
          message: r.summary.isNotEmpty ? r.summary : t.leafRetryHint,
          onRetake: () => Navigator.of(context).pop(),
        ),
      ];
    }

    final accent = r.healthy ? kBrand : bandColor(r.severityBand);
    final sev = r.severityPercentage ?? 0;

    return [
      // headline
      Row(
        children: [
          Icon(
            r.healthy ? IconlyBold.shield_done : IconlyBold.danger,
            color: accent,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.healthy
                      ? t.healthyLeaf
                      : localizedClassName(r.diseaseType, t),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                if (r.summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      r.summary,
                      style: TextStyle(color: kTextSub, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: StatTile(
              icon: IconlyBold.chart,
              label: t.severity,
              color: accent,
              value: r.healthy
                  ? const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kBrand,
                      ),
                    )
                  : CountUp(
                      sev,
                      suffix: '%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
              sub: r.severityBand.toUpperCase(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              icon: IconlyBold.activity,
              label: t.confidence,
              color: const Color(0xFF3B82F6),
              value: CountUp(
                r.confidence * 100,
                suffix: '%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B82F6),
                ),
              ),
              sub: _conf(r.confidence, t),
            ),
          ),
        ],
      ),

      if (!r.healthy && sev > 0) ...[
        const SizedBox(height: 16),
        AnimatedBar(fraction: sev / 100, color: accent),
      ],

      if (r.affectedRegions.isNotEmpty)
        SectionCard(
          icon: IconlyBold.show,
          title: t.whatWeSee,
          child: Text(
            r.affectedRegions,
            style: TextStyle(color: kTextSub, height: 1.45),
          ),
        ),

      if (r.treatments.isNotEmpty)
        SectionCard(
          icon: IconlyBold.shield_done,
          title: t.recommendedTreatment,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < r.treatments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          r.treatments[i],
                          style: TextStyle(height: 1.4, color: kText),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

      InfoCard(
        icon: IconlyBold.info_circle,
        color: const Color(0xFF64748B),
        text: t.leafDisclaimer,
      ),

      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(IconlyLight.camera, size: 18),
        label: Text(t.takeAnotherPhoto),
      ),
    ];
  }

  String _conf(double c, AppLocalizations t) =>
      c >= 0.75 ? t.high : (c >= 0.5 ? t.medium : t.low);
}
