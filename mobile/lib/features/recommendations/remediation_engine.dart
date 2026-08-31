import 'berry_analysis.dart';

/// Export destination — decides which actives are legal and their residue rules.
enum Market {
  eu('European Union', 'EU'),
  usa('United States', 'USA'),
  japan('Japan', 'JP'),
  local('Local / domestic', 'Local');

  final String label;
  final String short;
  const Market(this.label, this.short);
}

/// One treatment option surfaced to the farmer, already market-checked.
class TreatmentOption {
  final String name; // active ingredient / measure
  final String? mix; // e.g. "5 ml per 10 L water"
  final String method; // how to apply
  final bool allowedInMarket; // false → shown struck-through with the reason
  final String? restriction; // why it's not allowed (e.g. "Banned in the EU")
  final String phi; // pre-harvest interval note
  final bool isChemical;

  const TreatmentOption({
    required this.name,
    this.mix,
    required this.method,
    required this.allowedInMarket,
    this.restriction,
    required this.phi,
    this.isChemical = true,
  });
}

/// The full remediation advice for a berry analysis + market.
class Remediation {
  final String action; // headline action
  final List<TreatmentOption> options;
  final List<String> warnings;
  final String exportNote;

  const Remediation({
    required this.action,
    required this.options,
    required this.warnings,
    required this.exportNote,
  });
}

/// Turns a [BerryAnalysis] + [Market] into safe, compliant remediation.
///
/// Rules are the client's severity table (image 3) extended with a
/// market → allowed-active gate. The one hard regulatory fact encoded is that
/// **Fipronil is banned/withdrawn in the EU** — a real barrier for export pepper.
/// Exact MRL and PHI values are country- and formulation-specific and MUST be
/// confirmed with the local authority (e.g. Sri Lanka EDB / DOA); they are
/// surfaced as explicit "confirm" notes rather than fabricated numbers.
class RemediationEngine {
  static const String _confirmPhi =
      'Observe the pre-harvest interval and do not harvest for export until '
      'residues clear — confirm the exact days with your agri authority.';

  static Remediation forAnalysis(BerryAnalysis a, Market market) {
    if (!a.isBerryCluster) {
      return const Remediation(
        action: 'No advice — the image is not a berry cluster.',
        options: [],
        warnings: [],
        exportNote: '',
      );
    }

    if (a.healthy) {
      return Remediation(
        action: 'No treatment needed — cluster looks export-clean.',
        options: const [],
        warnings: const [],
        exportNote: _exportNote(a, market, treated: false),
      );
    }

    final isLaceBug = a.problemType.toLowerCase().contains('lace');

    // Unknown / non-lace problems: don't guess a chemical.
    if (!isLaceBug) {
      return Remediation(
        action:
            'Have an agronomist confirm the problem before any chemical use.',
        options: const [
          TreatmentOption(
            name: 'Remove and destroy affected berries',
            method: 'Prune and dispose away from the field to limit spread.',
            allowedInMarket: true,
            phi: 'No residue — safe for export.',
            isChemical: false,
          ),
        ],
        warnings: const [
          'Problem not confidently identified — chemical treatment is not '
              'recommended without expert diagnosis.',
        ],
        exportNote: _exportNote(a, market, treated: false),
      );
    }

    // --- Lace bug damage: the client's 70% rule ---
    if (a.severityPercentage > 70) {
      return Remediation(
        action: 'Severe damage (>70%) — remove affected berries from the tree.',
        options: const [
          TreatmentOption(
            name: 'Remove affected berries',
            method:
                'Pick and destroy heavily damaged berries to stop spread and '
                'protect the rest of the crop.',
            allowedInMarket: true,
            phi: 'No residue — keeps the remaining lot export-eligible.',
            isChemical: false,
          ),
        ],
        warnings: const [
          'Spraying at this stage adds residue for little benefit — removal is '
              'both the effective and the export-safe choice.',
        ],
        exportNote: _exportNote(a, market, treated: false),
      );
    }

    // Mild–moderate (≤70%): chemical options, market-filtered.
    final fipronilAllowed = market != Market.eu;
    return Remediation(
      action: 'Mild–moderate damage (≤70%) — treat, then respect residue rules.',
      options: [
        const TreatmentOption(
          name: 'Cultural control (remove worst berries)',
          method: 'Remove the most damaged berries first to lower pest pressure.',
          allowedInMarket: true,
          phi: 'No residue — safe for export.',
          isChemical: false,
        ),
        TreatmentOption(
          name: 'Fipronil',
          mix: '5 ml per 10 L water',
          method: 'Spray evenly on the affected pepper plant.',
          allowedInMarket: fipronilAllowed,
          restriction:
              fipronilAllowed ? null : 'Banned/withdrawn in the EU — do not use for EU-bound export.',
          phi: _confirmPhi,
        ),
        const TreatmentOption(
          name: 'Acetamiprid',
          mix: '25 ml per 10 L water',
          method: 'Spray evenly on the affected pepper plant.',
          allowedInMarket: true,
          phi: _confirmPhi,
        ),
      ],
      warnings: [
        'Wear protective equipment (gloves, mask) when mixing and spraying.',
        if (market == Market.eu)
          'For EU export, use Acetamiprid or cultural control only — Fipronil '
              'residues will fail EU limits.',
      ],
      exportNote: _exportNote(a, market, treated: true),
    );
  }

  static String _exportNote(BerryAnalysis a, Market market, {required bool treated}) {
    final base =
        'Grading for ${market.label}: ~${a.severityPercentage.toStringAsFixed(0)}% '
        'of the spike shows damage.';
    if (treated) {
      return '$base A treated lot is only export-eligible once residues fall '
          'within ${market.short} limits — keep a record of the product, dose '
          'and date for traceability.';
    }
    return base;
  }
}
