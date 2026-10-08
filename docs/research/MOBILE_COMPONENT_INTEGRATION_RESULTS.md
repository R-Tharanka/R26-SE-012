# Four-Component Mobile Integration Results

Date: 2026-10-08

## Objective

Integrate the separately supplied Pest Detection, Leaf Disease Detection, and
Berry Disease Detection Flutter implementation into the current application
without replacing or weakening the authoritative Phase 7 Berry Grading and
Export Price Forecasting workflow.

This is application integration evidence. It is not model training, predictive
evaluation, field validation, or a claim of production readiness.

## Source and authority boundary

The supplied `other members components - mobile` directory is a complete older
Flutter application rather than three isolated packages. Its pest, leaf, and
berry-disease code was treated as authoritative for those domains. The current
repository remained authoritative for:

- the application dashboard structure and theme;
- everything under `mobile/lib/features/grading_forecast/`;
- the Phase 7 FastAPI/ONNX integration and Phase 6 response contract;
- grading rejection, uncertainty, and exact grade-price routing;
- all frozen research artifacts and model binaries.

The imported grading/forecast screens, model, API client, Grade 3 behavior,
quality-score presentation, recommendation rules, and legacy price behavior
were not copied.

## Component inventory

Pest and leaf health use the combined `PlantHealthScannerScreen`, shared
`ScannerView`, `YoloDetector`, Gemini detection service, Claude crop refinement,
and pest/leaf recommendation screens. Berry disease uses the corresponding
berry scanner and berry recommendation flow through the same shared runtime.

The current Phase 7 grading feature continues to use its existing capture,
strict response model, API service, result screen, frozen forecast presentation,
and backend URL configuration.

## Conflicts resolved

- The imported three-card home screen was not used. Its locale selector was
  adapted into the current four-feature dashboard.
- The imported `berry_disease/screens` path was adapted to the existing
  `berry_disease/berry_scanner_screen.dart` path, avoiding duplicate screens.
- Imported background-isolate inference was retained on native targets. A
  direct-execution web fallback was added so the browser grading path continues
  to compile where worker-isolate/native-interpreter behavior differs.
- Imported on-demand recommendations replaced the older recommendation
  prefetch behavior for pest, leaf, and berry-disease scans.
- The imported Anthropic v7 client contract and `claude-haiku-4-5` selection
  were retained for the outsourced components.
- The current `ScannerModelConfig` safeguards, theme, Android SDK settings,
  broad asset declarations, and Phase 7 grading source were retained.
- Localization keys describing the legacy grader remain inert catalog entries;
  they were not attached to the current grading screens. A later scoped
  implementation added new Phase 7-specific English, Sinhala, and Tamil text
  while preserving the current scientific workflow and stable API values.

## Implemented integration

- Added persisted English, Sinhala, and Tamil language selection.
- Added localized shell labels, scanner instructions, progress states, safe
  errors, findings, class labels, and recommendation/result screens for the
  three imported domains.
- Kept scientific class identifiers and internal routing values in English;
  localization occurs only at presentation boundaries.
- Added background JPEG decoding, TFLite inference, exemplar preparation, and
  crop preparation for native mobile targets.
- Added imported Gemini structured-response handling and Claude crop refinement.
- Preserved safe TFLite fallback when cloud configuration is absent or fails.
- Added the imported source directory to `.gitignore`; it remains untouched as
  a local comparison source and is not part of the built app.

## Dependency and configuration changes

Flutter localization, `intl`, and `shared_preferences` were added.
`anthropic_sdk_dart` was updated to the imported v7 contract and the `image`
dependency was aligned with the imported runtime. Existing model/data/logo
asset declarations were preserved. Flutter regenerated the macOS plugin
registrant for `shared_preferences`; Android SDK settings were not changed.

The combined mobile runtime recognizes:

```text
PEPPER_API_BASE_URL
GEMINI_API_KEY
ANTHROPIC_API_KEY
```

Values are supplied through ignored build-time configuration. No `.env` file or
secret was copied, inspected, logged, or committed.

## Integrity evidence

The current and imported projects contained 37 overlapping pest/leaf/berry
model/reference assets, all byte-identical before integration. No asset was
replaced. Post-integration important hashes are:

| Artifact | SHA-256 |
|---|---|
| Frozen Phase 3 `best.pt` | `e825278e0cf8eaff64cd05a2941cf96794e573027823a0ccd308bbc3f1a418ca` |
| Phase 7 `best.onnx` | `f8bb36b3ce9c354fd0707f555dbff88bc4f24606b4b93be99a74b03e6db54d38` |
| Berry-disease TFLite | `48207a4189a4b33ea74e4669203b75d1d7295972f17129d677c3d4a9ac58fe1f` |
| Leaf TFLite | `285f31bd32094a21b4a7c86d90cadcff9c51f325bf1b58d31f599418d69beaf0` |
| Pest TFLite | `fa9e343a5d9df0799dc0e4c81391936ffe3d999240774d1678c29c7baa0886b9` |

At the time of the four-component merge, `git diff` reported no change under
`mobile/lib/features/grading_forecast/`. The later localization work changed
only Phase 7 presentation and safe mobile error classification; it did not
change the backend contract, models, thresholds, routes, or scientific rules.
Backend Phase 7 focused verification passed 15/15 tests after the original
mobile integration.

## Automated verification

- Direct Dart analysis of `mobile/lib` and `mobile/test`: no issues found.
- Focused Phase 7 backend/API/startup verification: 15 passed.
- Added locale persistence, localized class-label, four-component navigation,
  current Phase 7 route, and legacy Grade 3 absence checks.
- Existing YOLO geometry/NMS, overlay, scan-result, Phase 7 parser, and API tests
  remain in the suite.
- The later Phase 7 localization/API/contract suite passed 12/12 tests, and
  direct Dart analysis reported no issues.
- `flutter test` and the bounded debug APK build produced no output while local
  Flutter/Dart/Gradle processes remained occupied. Both were stopped; no test or
  build pass is claimed from those attempts.

## Manual acceptance still required

On an emulator or physical Android device:

1. verify first-launch and later language selection;
2. exercise camera/gallery pest, leaf, and berry-disease scans;
3. verify TFLite fallback without cloud keys;
4. verify authorized Gemini/Claude development-key behavior;
5. verify camera recovery after gallery/background transitions;
6. rerun the five established Phase 7 grading cases.

## Limitations

- Gemini and Anthropic keys embedded in an APK or browser bundle are
  recoverable. The current direct-provider design is suitable only for
  controlled development; public deployment requires a protected backend proxy.
- Direct provider behavior on Flutter web is not accepted by this integration.
- Device tests, live cloud calls, Flutter widget-test execution, and APK build
  completion are not claimed in this run.
- The localization has not received independent linguistic review.
- No component received new model training, predictive evaluation, calibration,
  domain-shift evidence, or field validation.

## Status

`IMPLEMENTED; STATIC AND BACKEND VERIFICATION PASSED; DEVICE/FLUTTER-RUNNER ACCEPTANCE PENDING`.
