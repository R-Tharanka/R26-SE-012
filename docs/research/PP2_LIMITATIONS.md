# PP2 Limitations

Last updated: 2026-08-27

This document records limitations that must be stated honestly during PP2.

## Camera-Based Grading Limitation

The berry grading system is a camera-based visual estimation system. It can support visual grading indicators such as color, texture, visible defects, visible foreign matter, and rough apparent quality.

It cannot measure:

- moisture content;
- total ash;
- acid-insoluble ash;
- volatile oil;
- piperine;
- non-volatile ether extract;
- crude fibre;
- bulk density;
- laboratory-level hygiene or adulteration compliance.

Therefore, the system must not be presented as official SLS certification.

Recommended wording:

Camera-based visual estimate only. Chemical requirements and bulk density are not measured. Laboratory testing is required for official certification.

## Berry Dataset Limitations

Known limitations:

- Dataset is small for deep learning: 168 physical sample groups and 671 readable images.
- Multiple images from the same physical sample exist.
- Some samples have fewer or more than four images.
- Images were taken with at least two smartphone devices.
- Some images may have different orientations.
- Some images may have background-heavy framing.
- Some images may include hand, white paper, or metal sheet backgrounds.
- Some images may be blurred or less focused.
- Supporting labels such as size quality, color quality, texture quality, broken level, light berry level, pinhead level, mould, insect damage, and foreign matter are not manually verified for V2.
- V2 has five non-4-image samples: Grade 1 sample_028, Grade 1 sample_030, Grade 3 sample_010, Grade 1 sample_002, and Grade 1 sample_018.

Required mitigation:

- Use sample-level train/validation/test splitting.
- Do not split images from the same physical sample across different sets.
- Do not fabricate missing metadata.
- Use only automatically recoverable metadata for PP2.

## Price Dataset Limitations

Known limitations:

- The raw source is farm-gate market price data, not confirmed export transaction price data.
- Some weeks are missing from the source.
- Dates are mostly weekly but not perfectly regular.
- Grade 2 has sparse historical coverage, especially in earlier years.
- V2 National Grade 2 average has 161 observed dates only: 2022: 6, 2023: 27, 2024: 49, 2025: 49, 2026: 30.
- District-level Grade 2 coverage is inconsistent.
- Missing Grade 2 values must not be treated as zero.
- Missing Grade 2 values must not be invented or interpolated as if they were observed.

Required mitigation:

- Use National Grade 1 average farm-gate weekly price as the primary PP2 forecasting target.
- Document Grade 2 as a limitation and future work.
- Track missing weeks and temporal gaps.
- Avoid leakage-causing backfill from future data.

## Model Limitations

Berry:

- V1 MobileNetV2 was trained on an old 360-image dataset.
- V1 split had no separate test set.
- V1 Grade 2 recall was weak.
- V2 MobileNetV2 was evaluated on the leakage-safe sample-level test split with accuracy 0.8073, weighted F1 0.8076, and Grade 2 recall 0.8889.
- V1 and V2 metric differences are not directly equivalent because V2 uses a different expanded dataset and a sample-level train/validation/test methodology.
- V2 Grade 3 remains the weakest class by F1 in the completed baseline.
- The completed V2 model is still trained from a small dataset, so external generalization to new devices, lighting conditions, and backgrounds is not proven yet.

Forecasting:

- V1 RandomForest had poor test R2.
- Price forecasting is short-horizon only.
- Phase 3 V2 forecasting metrics have not been generated yet.
- V2 lag and rolling features use previous available observations, not guaranteed previous calendar weeks, because the source has missing weekly intervals.
- No macroeconomic, export volume, weather, exchange rate, or global market features are included before PP2.
- RandomForest may not outperform naive persistence.

## Integration Limitations

- Existing backend can fall back to heuristic/demo mode if real model artifacts are unavailable.
- PP2 demo must explicitly identify whether real artifacts or fallback logic were used.
- Firebase live writes are not guaranteed unless credentials are configured.
- Flutter flow exists but may need environment validation.

## Script Safety Limitation

Several older scripts still default to V1 output paths. Accidentally running them without V2-specific arguments can overwrite old label or processed CSV artifacts. Before using any old data-preparation script, check its default input/output paths and prefer the V2 scripts created for Phase 1.

For berry model work after Phase 2, do not run the V1 default training/evaluation/export commands unless the intention is explicitly to reproduce V1. Use the explicit V2 arguments recorded in `docs/research/EXPERIMENT_LOG.md` and keep all V2 model outputs under `ml/grading_forecast/berry_grading/models/v2/`.

For price forecasting after Phase 3 preparation, do not run the no-argument forecasting commands for V2 work. Use explicit `price_v2`, `models/v2`, and `_outputs/v2` paths so V1 artifacts are not overwritten.

## PP2 Scope Limitations

Not required before PP2:

- LSTM.
- ARIMA/SARIMA.
- XGBoost.
- Prophet.
- Segmentation-based berry isolation.
- Manual annotation of detailed visual defect labels.
- Full Firebase deployment validation.
- TFLite/on-device inference.
- Production deployment.
