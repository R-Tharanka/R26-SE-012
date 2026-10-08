# Phase 7 Application Run, Test, and Android Release Guide

This is the operational guide for the Phase 7 integrated pipeline:

```text
Flutter web / Android emulator / Android device
    -> FastAPI Phase 7 endpoint
    -> frozen ONNX grading runtime
    -> frozen Phase 5 forecast records
    -> authoritative Phase 6 decision engine
```

It is intentionally separate from the older `project_commands_guide.md`, which
contains legacy pre-Phase-7 commands and retired endpoint descriptions. Use this
document for the current rejection-first Phase 7 workflow.

## 1. Scope and limits

This guide starts the local demonstration system. It does not train a model,
change frozen thresholds, create a live price forecast, or validate field
robustness.

The selected mobile architecture is backend inference. The Android and web
clients upload an image to the local Phase 7 backend; neither claims on-device
ONNX or TFLite execution. The backend uses the frozen
`v3_phase3_followup/best.onnx` artifact.

The `market` section is frozen research evidence, not a live market price,
buyer offer, trading signal, or financial recommendation.

## 2. Prerequisites

Run the commands in PowerShell. These paths reflect the current local setup:

```text
Repository: D:\work\Year - 4\pepper\project\multimodal-pepper-ai-decision-support
Python environment: .venv
Flutter SDK: C:\test-by-me\flutter\flutter
Android SDK: C:\Users\thara\AppData\Local\Android\Sdk
```

The current Flutter app package is `com.example.mobile`; replace it with a
unique package name before distributing any APK outside local testing.

## 3. Start and verify the backend

Open terminal 1 at the repository root:

```powershell
cd "D:\work\Year - 4\pepper\project\multimodal-pepper-ai-decision-support"
```

Install backend requirements once if needed:

```powershell
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
```

Start the backend. `0.0.0.0` is required for an Android emulator or a physical
device to reach the Windows host:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000
```

Leave this terminal running. The model is loaded during application startup.

In terminal 2, check availability and the initialized runtime:

```powershell
Invoke-RestMethod "http://127.0.0.1:8000/api/v1/grading-forecast/health" | ConvertTo-Json -Depth 10
Invoke-RestMethod "http://127.0.0.1:8000/api/v1/grading-forecast/ready" | ConvertTo-Json -Depth 10
```

The readiness endpoint must report a ready runtime before testing a client.
FastAPI interactive documentation is available at:

```text
http://127.0.0.1:8000/docs
```

### Direct API smoke test

This removes the Flutter client from the diagnosis if an issue appears:

```powershell
curl.exe -X POST "http://127.0.0.1:8000/api/v1/grading-forecast/analyze" `
  -F "image=@data/raw/Pepper Berry Grading V3.yolov8/test/images/20260508_160550_jpg.rf.BUF1sZWo8GvE4UCSfj74.jpg"
```

## 4. Controlled Phase 7 test images

Use these existing evidence images. Do not add them to, or replace, historical
evaluation partitions.

| File | Expected client outcome | Expected market behavior |
|---|---|---|
| `data/raw/Pepper Berry Grading V3.yolov8/test/images/20260508_160550_jpg.rf.BUF1sZWo8GvE4UCSfj74.jpg` | accepted Grade 1 case | Grade 1 route only |
| `data/raw/Pepper Berry Grading V3.yolov8/test/images/20260508_233543_jpg.rf.GIitSA5jym8tu4es92nw.jpg` | accepted Grade 2 case | Grade 2 route only |
| `data/external/phase3_followup_negatives/aerial_crop_imagery/p3fu_aerial_crop_imagery_0010.jpg` | `NO_PEPPER` / `REJECT` | no market output |
| `data/external/phase3_followup_negatives/agricultural_materials/p3fu_agricultural_materials_0002.jpg` | `POOR_IMAGE` / `REJECT` | no market output |
| `data/raw/Pepper Berry Grading V3.yolov8/train/images/20260814_163149_jpg.rf.akYgyVxsjFSkI9lbWxrt.jpg` | uncertain case | no market output |

Decision wording can vary with the frozen engine response. The invariant is
that rejection and uncertainty states must not enter price routing.

## 5. Run and test in a browser

With the backend from section 3 still running, open terminal 3:

```powershell
cd "D:\work\Year - 4\pepper\project\multimodal-pepper-ai-decision-support\mobile"
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" pub get
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" run -d chrome --dart-define=PEPPER_API_BASE_URL=http://127.0.0.1:8000
```

Flutter opens a Chrome window. In the app, choose the Berry Grading and Export
Price Forecasting flow, select one of the files in section 4 from the Windows
file picker, and submit it.

The browser runs on a temporary `localhost` port. The backend permits local
browser origins, so no CORS change is required. If Chrome opens but analysis
fails, first open `http://127.0.0.1:8000/api/v1/grading-forecast/ready` in the
same browser and check the backend terminal for the request/error.

Stop the web run with `q` or `Ctrl+C`. During development, `r` performs Flutter
hot reload.

### Optional web release build

This produces static web files but does not host them:

```powershell
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" build web --release --dart-define=PEPPER_API_BASE_URL=http://127.0.0.1:8000
```

Output: `mobile/build/web/`.

`127.0.0.1` is suitable only when the browser and backend run on the same
computer. Before hosting the web build elsewhere, deploy the backend over HTTPS
and rebuild using its HTTPS URL. Do not expose the local research backend to the
internet merely to test the web client.

## 6. Run and test on an Android emulator

Start an Android virtual device in Android Studio's Device Manager. Verify it:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

An emulator uses `10.0.2.2` to reach its Windows host. It must not use
`127.0.0.1:8000`.

Run Flutter from `mobile/`:

```powershell
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" run `
  -d emulator-5554 `
  --dart-define=PEPPER_API_BASE_URL=http://10.0.2.2:8000
```

Replace `emulator-5554` with the identifier printed by `flutter devices` or
`adb devices`.

To confirm the network path before opening the Flutter app, open the emulator's
Chrome browser and visit:

```text
http://10.0.2.2:8000/api/v1/grading-forecast/ready
```

### Put controlled files in the emulator

From repo root:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb push "data\raw\Pepper Berry Grading V3.yolov8\test\images\20260508_160550_jpg.rf.BUF1sZWo8GvE4UCSfj74.jpg" "/sdcard/Download/phase7_grade1.jpg"
& $adb push "data\raw\Pepper Berry Grading V3.yolov8\test\images\20260508_233543_jpg.rf.GIitSA5jym8tu4es92nw.jpg" "/sdcard/Download/phase7_grade2.jpg"
& $adb push "data\external\phase3_followup_negatives\aerial_crop_imagery\p3fu_aerial_crop_imagery_0010.jpg" "/sdcard/Download/phase7_non_pepper.jpg"
& $adb push "data\external\phase3_followup_negatives\agricultural_materials\p3fu_agricultural_materials_0002.jpg" "/sdcard/Download/phase7_poor_image.jpg"
& $adb push "data\raw\Pepper Berry Grading V3.yolov8\train\images\20260814_163149_jpg.rf.akYgyVxsjFSkI9lbWxrt.jpg" "/sdcard/Download/phase7_uncertain.jpg"
```

Use the app's gallery picker and choose the copies under Downloads. Gallery
selection is preferable to an emulator camera for this controlled verification.
The Phase 7 picker deliberately requests neither resizing nor JPEG quality
conversion; changing those options changes the frozen quality and uncertainty
decisions. Rerun all five cases after any picker or image-transport change.

The corrected researcher-operated emulator verification on 2026-10-08 passed
all five controlled cases: Grade 1, Grade 2, non-pepper, poor-image, and
uncertain-grade. Preserve this pass-through behavior in future mobile changes.

## 7. Run and test on a physical Android device

Enable Developer options and USB debugging on the device, then connect it by
USB. Confirm the device and accept its authorization prompt:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

### Recommended USB path: ADB reverse

This sends the device's port 8000 back to the Windows backend without needing a
LAN address. It is for USB-debug sessions only:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb reverse tcp:8000 tcp:8000
```

Launch Flutter with the device ID reported by `flutter devices`:

```powershell
cd "D:\work\Year - 4\pepper\project\multimodal-pepper-ai-decision-support\mobile"
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" run `
  -d YOUR_DEVICE_ID `
  --dart-define=PEPPER_API_BASE_URL=http://127.0.0.1:8000
```

On a physical device, `127.0.0.1` works only because `adb reverse` was set.
After disconnecting USB, that route no longer exists.

### Wi-Fi/LAN path

For a phone on the same trusted Wi-Fi network, find the Windows IPv4 address:

```powershell
ipconfig
```

Use the IPv4 address of the active Wi-Fi adapter, for example `192.168.1.50`:

```powershell
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" run `
  -d YOUR_DEVICE_ID `
  --dart-define=PEPPER_API_BASE_URL=http://192.168.1.50:8000
```

The backend must still be started with `--host 0.0.0.0`. Allow Python through
Windows Firewall only on a trusted private network. This HTTP research setup is
not suitable for public Wi-Fi, internet exposure, or production deployment.

Use the phone camera only as an interface test. It is not Phase 8 field
validation and must not be reported as evidence of field robustness.

## 8. Android release APK

### Local release candidate

The current Android Gradle configuration signs the `release` build with the
debug key. Therefore it is usable for local installation/testing only, not for
Play Store distribution or a security-sensitive release.

Build it from `mobile/`:

```powershell
cd "D:\work\Year - 4\pepper\project\multimodal-pepper-ai-decision-support\mobile"
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" build apk --release `
  --dart-define=PEPPER_API_BASE_URL=http://10.0.2.2:8000
```

Output:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

That emulator URL is only correct if the APK is installed on an emulator. For a
USB device using `adb reverse`, build with `http://127.0.0.1:8000`; for a LAN
device, build with the trusted LAN URL. The compile-time API URL is embedded in
the APK, so rebuild when that target changes.

Install a local test APK over USB:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb install -r "build\app\outputs\flutter-apk\app-release.apk"
```

### Distributable signed release

Before distributing an APK, complete these non-research Android release tasks:

1. Replace `com.example.mobile` with a unique application ID.
2. Create and safely back up an upload keystore; losing it prevents future
   updates signed with the same identity.
3. Keep the keystore and its passwords out of Git. The Android `.gitignore`
   already excludes `key.properties`.
4. Add a release signing configuration that reads the local `key.properties`
   file instead of using the debug key.
5. Use an HTTPS backend URL with appropriate authentication, deployment, and
   privacy controls; do not distribute an APK configured for a developer's
   local computer.
6. Build and test a signed app bundle for store distribution:

```powershell
& "C:\test-by-me\flutter\flutter\bin\flutter.bat" build appbundle --release `
  --dart-define=PEPPER_API_BASE_URL=https://YOUR_BACKEND_HOST
```

Expected bundle output:

```text
mobile/build/app/outputs/bundle/release/app-release.aab
```

Creating the signing setup is deliberately not automated in Phase 7 because it
requires ownership of a private keystore, final package identity, and a secure
deployment target.

## 9. Verification checklist

For each client path, retain only screenshots/log excerpts that do not expose
personal images or sensitive details.

- Backend `/health` and `/ready` respond successfully.
- Browser, emulator, or device can reach the backend using its correct address.
- A Grade 1 image routes only to Grade 1 evidence.
- A Grade 2 image routes only to Grade 2 evidence.
- A non-pepper and poor-image input return rejection and `market = null`.
- An uncertain input returns uncertainty and `market = null`.
- `UNCERTAIN_GRADE` must not be treated as `HIGH_UNCERTAINTY_OUTLOOK`: the
  former blocks pricing, while the latter follows an accepted grade.
- Accepted results show frozen reference-price/forecast evidence and a Phase 6
  category, not a live-price or trading claim.
- The backend terminal records the request outcome without retaining uploaded
  image contents.

## 10. Troubleshooting

| Symptom | Check / resolution |
|---|---|
| `Cannot reach the research backend` | Verify `/ready` locally first, then use `127.0.0.1` for browser, `10.0.2.2` for emulator, or `adb reverse`/LAN IP for a device. |
| Browser CORS error | Start the current backend in section 3; it permits `localhost` and `127.0.0.1` local browser origins. Do not open the web app from a random host without explicitly reviewing backend CORS. |
| Emulator connection refused | Confirm `http://10.0.2.2:8000/api/v1/grading-forecast/ready` works in emulator Chrome and that the backend uses `--host 0.0.0.0`. |
| Windows firewall prompt | Permit Python only on the trusted private network necessary for the test. |
| Image picker has no copied files | Check `& $adb shell ls -l /sdcard/Download`, then reopen the picker and select Downloads. |
| First Flutter run takes a long time | The initial Android build resolves/compiles Gradle, Kotlin, Flutter, and plugin artifacts. Let it continue while Gradle/Java uses CPU; later runs use caches. |
| Port 8000 already in use | Reuse the existing project backend or stop it cleanly with `Ctrl+C`. Inspect with `Get-NetTCPConnection -LocalPort 8000 -State Listen`. |

### API validation and error semantics

| HTTP status | Meaning | Client action |
|---|---|---|
| `400` | Empty, unreadable, or invalid image | Select a valid image and retry. |
| `413` | Upload exceeds 10 MB or decoded dimensions exceed the safe limit | Choose a smaller original image; do not modify frozen thresholds. |
| `415` | Unsupported or animated image | Use a single-frame JPEG, PNG, or WEBP. |
| `422` | Malformed multipart request | Confirm the multipart field is named `image`. |
| `429` | Hosted service rate/resource limit | Wait before retrying. |
| `500` | Invalid/unexpected integrated response was withheld | Record the analysis time and inspect backend logs; do not fabricate a result. |
| `503` | ONNX, frozen forecast evidence, or grade-price routing is unavailable | Check `/ready`; retry only after it returns HTTP 200 and `ready`. |
| `502` / `504` | Hosting proxy could not complete the upstream request | Verify Railway deployment, target port, health, and runtime logs. |

The local and hosted `/ready` endpoint is stricter than `/health`. `/health`
proves that the process can answer HTTP; `/ready` verifies the frozen ONNX and
forecast source. A non-ready response is HTTP 503 and must block testing.

## 11. Evidence boundary

A successful browser, emulator, or USB-device run proves local integration of
the current backend/client path. It does not prove field/device/domain-shift
robustness, production accuracy, official-grade equivalence, calibrated
confidence, reliable future-price prediction, economic profitability, or user
benefit. Phase 8 remains the separate prospective field-validation phase.
