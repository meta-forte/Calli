# Application Security, OWASP, and Accessibility Tests To Be Covered

## Overview

Even though HanziSlate (Calli) requests **zero device permissions** (no contacts, photos, media directories, microphone, camera, or external storage) and collects **zero personal identifiable information (PII)**, it maintains an active local and network attack surface:
- **SQLite Database** (`PracticeStorageService` in `Calli/Sources/Services/PracticeStorageService.swift`) storing daily character practice counts in `practice.sqlite`.
- **Remote Update Check & External URL Opener** (`AppUpdateService` in `Calli/Sources/Services/AppUpdateService.swift`) fetching `version.json`, verifying Ed25519 digital signatures, and opening `appStoreUrl` via `UIApplication.shared.open`.
- **User Input & Custom Parsers** (`CharacterSearchIndex` in `Calli/Sources/Models/CharacterSearch.swift`, `StrokePathParser` in `Calli/Sources/Models/StrokePathParser.swift`, `PropertyConfig` in `Calli/Sources/Services/AppUpdateService.swift`).
- **App Bundle & Privacy Configuration** (`Calli/Info.plist`, `Calli/Resources/PrivacyInfo.xcprivacy`, and `UserDefaults`).

---

## 1. OWASP Mobile Top 10 (2024) & MASVS Applicability

| OWASP Category | Applicable? | Scope in Calli |
| :--- | :--- | :--- |
| **M1: Improper Credential Usage** | **Yes (Static Audit)** | Ensure no private signing keys (`update_signing_key.pem`, `.p8`, `.p12`) or developer credentials leak into the app bundle. |
| **M2: Inadequate Supply Chain Security** | **Yes** | Verify integrity and valid schema of bundled datasets (`characters.json`, `others.json`, `strokes.json`, `others_strokes.json`, `NotoSansSC.ttf`). |
| **M3: Insecure Authentication / Authorization** | **N/A** | App has no user accounts, login flows, or session tokens. |
| **M4: Insufficient Input / Output Validation** | **Yes (High Priority)** | Parameterized SQL queries in `PracticeStorageService`, strict App Store URL scheme/host whitelisting in `AppUpdateService`, and search/SVG parser fuzzing. |
| **M5: Insecure Communication** | **Yes (High Priority)** | App Transport Security (ATS) enforcement in `Info.plist` and Ed25519 signature verification of `version.json` to prevent MITM forced-update lockouts or phishing redirects. |
| **M6: Inadequate Privacy Controls** | **Yes (App Store Requirement)** | `PrivacyInfo.xcprivacy` declaration (`NSPrivacyTracking = false`, Required Reason API `CA92.1` for `UserDefaults`) and verifying zero sensitive permission keys in `Info.plist`. |
| **M7: Insufficient Binary Protections** | **Yes** | Verify Position Independent Executable (PIE), Automatic Reference Counting (ARC), and Stack Canaries (`___stack_chk_guard`) in compiled binaries. |
| **M8: Security Misconfiguration** | **Yes** | Ensure `NSAllowsArbitraryLoads` is disabled and SQLite database file protection (`FileProtectionType.completeUntilFirstUserAuthentication`) is applied. |
| **M9: Insecure Data Storage** | **Low / Scoped** | No PII is stored; verify `practice.sqlite` and `UserDefaults` remain isolated inside the iOS sandbox container. |
| **M10: Insufficient Cryptography** | **Yes** | Verify `CryptoKit` Ed25519 signature verification (`Curve25519.Signing`) accepts valid signatures and rejects tampered payloads or invalid keys. |

---

## 2. Application Security Test Cases

### 2.1 Input Validation & Injection (OWASP M4 / MASVS-CODE)
- **SEC-01: SQLite Injection Resilience in Practice Log**
  - **Target:** `PracticeStorageService.recordPractice(character:date:)`, `getPracticeCount(character:date:)`, and `getTotalPracticeCount(character:)`.
  - **Test:** Pass SQL injection payloads (`"'; DROP TABLE practice_log; --"`, `"爱' OR '1'='1"`, null bytes `\0`, and multi-scalar Unicode sequences) as `character` and `date`.
  - **Expected:** `sqlite3_bind_text` treats the payload strictly as a literal string; `practice_log` table remains intact and subsequent queries succeed.
- **SEC-02: Untrusted Redirect / URL Scheme Whitelisting on Update Action**
  - **Target:** `AppUpdateService.isValidAppStoreURL(_:)`, `appStoreURL`, and `openAppStore()`.
  - **Test:** Supply mocked `AppUpdateInfo` with malicious `app_store_url` strings: `javascript:alert(1)`, `file:///etc/passwd`, `tel://12345`, `http://apps.apple.com/app/id123`, `https://evil.example.com/app/id123`, and `https://apps.apple.com@evil.com/app/id123`.
  - **Expected:** Only `https://apps.apple.com/...` or `itms-apps://apps.apple.com/...` URLs pass validation; untrusted schemes or hosts are rejected and fall back safely to the default `https://apps.apple.com` URL.
- **SEC-03: Malformed Update Payload & Version String Fuzzing**
  - **Target:** `AppUpdateInfo` and `AppVersion`.
  - **Test:** Feed malformed JSON, empty objects, oversized `release_notes`, negative/overflow version numbers (`"999999999999999999999.0.-1"`), or non-numeric strings (`"1.0.beta;rm"`).
  - **Expected:** Decoder and comparator handle inputs gracefully without crash, hang, or false forced-update lockout.
- **SEC-04: Search & Parser Boundary Fuzzing (DoS Prevention)**
  - **Target:** `CharacterSearchIndex.searchWithContext(_:)`, `PinyinSyllable.parse(_:)`, and `StrokePathParser.parse(svgPath:canvasSize:)`.
  - **Test:** Pass 10,000-character search queries, repeated combining diacritics (`u\u{0308}\u{0308}\u{0304}...`), emojis, RTL control characters, and malformed SVG commands (`"M NaN Infinity Q 1e308 -1e308 Z"`).
  - **Expected:** Execution completes quickly without crashes or invalid CoreGraphics paths (NaN/Infinite points rejected).
- **SEC-05: UserDefaults Deserialization Bounds Check**
  - **Target:** `CharacterStore.selectedLevel`, `CharacterDetailView.tracingFontSize`, and `GridCellSize`.
  - **Test:** Write out-of-range values to `UserDefaults` (`kSelectedHSKLevel = -99` or `999`, `kTracingCharacterFontSize = -500` or `99999`, invalid `GridCellSize` raw value).
  - **Expected:** Values are clamped to valid bounds (`1...9` for HSK level, `160.0...520.0` for tracing font size, `.medium` for grid cell size).

### 2.2 Network, Transport & Cryptographic Verification (OWASP M5, M10 / MASVS-NETWORK, MASVS-CRYPTO)
- **SEC-06: App Transport Security (ATS) Configuration Audit**
  - **Target:** `Calli/Info.plist`.
  - **Test:** Parse `Info.plist` and verify `NSAllowsArbitraryLoads` is not enabled (`false` or absent). Only `NSAllowsLocalNetworking` is permitted for local simulator mock server testing.
- **SEC-07: Ed25519 Update Signature Verification**
  - **Target:** `AppUpdateService.verifySignedPayload(data:publicKeyBase64:)`.
  - **Test:**
    1. Valid Ed25519 signature over canonical JSON payload is accepted and decoded into `AppUpdateInfo`.
    2. Tampered `force_update: true` or modified `app_store_url` with original signature is rejected with a verification error.
    3. Payload signed with a different/rogue Ed25519 private key is rejected.
    4. Malformed base64 public key or signature is rejected.
- **SEC-08: Offline Operation & Local Bundle Integrity**
  - **Target:** `CharacterStore` and bundled JSON/font resources.
  - **Test:** Verify `characters.json`, `others.json`, `strokes.json`, `others_strokes.json`, and `NotoSansSC.ttf` load directly from the local app bundle without any network dependency.

### 2.3 Privacy, Sandbox & Binary Hardening (OWASP M1, M6, M7, M8 / MASVS-PRIVACY, MASVS-STORAGE, MASVS-RESILIENCE)
- **SEC-09: Zero-Permission Enforcement Test**
  - **Target:** `Calli/Info.plist`.
  - **Test:** Assert `Info.plist` contains zero sensitive permission keys (`NSContactsUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSAppleMusicUsageDescription`, `NSCalendarsUsageDescription`, `NSRemindersUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `NSUserTrackingUsageDescription`, `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`).
- **SEC-10: Apple Privacy Manifest (`PrivacyInfo.xcprivacy`) Validation**
  - **Target:** `Calli/Resources/PrivacyInfo.xcprivacy`.
  - **Test:** Load `PrivacyInfo.xcprivacy` from the bundle and assert:
    - `NSPrivacyTracking` == `false`
    - `NSPrivacyTrackingDomains` is empty
    - `NSPrivacyCollectedDataTypes` is empty
    - `NSPrivacyAccessedAPITypes` declares `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`.
- **SEC-11: Sandbox Isolation & File Protection Attributes**
  - **Target:** `PracticeStorageService`.
  - **Test:** Verify the default database path resides strictly inside the app's sandboxed `.documentDirectory` and applies `FileProtectionType.completeUntilFirstUserAuthentication`.
- **SEC-12: Secret & Private Key Leak Scan**
  - **Target:** `Bundle.main`.
  - **Test:** Enumerate bundled resources and assert no `.pem`, `.p8`, `.p12`, `.key`, `.jks`, `.keystore`, or `.env` files are packaged in the app bundle.
- **SEC-13: Mach-O Binary Hardening Audit**
  - **Target:** Loaded main executable Mach-O header (`_dyld_get_image_header`) and Objective-C/Swift runtime symbols.
  - **Test:** Verify `MH_PIE` (Position Independent Executable) flag is set on the executable header, and stack-protector (`___stack_chk_fail`) and ARC (`objc_retain` / `objc_release`) symbols are linked.

---

## 3. Accessibility (a11y) Test Cases

### 3.1 VoiceOver & Screen Readers
- **A11Y-01: Character Grid Cell Informative Accessibility Label & Trait**
  - **Target:** `CharacterCellView`.
  - **Test:** Verify each character cell formats its VoiceOver label with character, pinyin, meaning, and level (e.g., `"Character 爱, pinyin ài, meaning to love, HSK Level 1. Double tap to trace."` for HSK characters and `"Character 龍, pinyin lóng, meaning dragon, Other Character. Double tap to trace."` for non-HSK characters) and has the `.isButton` trait.
- **A11Y-02: Character Detail & Audio Controls VoiceOver Labels**
  - **Target:** `CharacterDetailView`.
  - **Test:** Verify all icon-only and action buttons expose clear accessibility labels:
    - Top and bottom audio buttons: `"Play pronunciation audio"`
    - Close button: `"Close"`
    - Previous / Next / Reset buttons: `"Previous character"`, `"Next character"`, `"Reset strokes"`
    - Font size button & slider: `"Tracing font size options"`, `"Tracing character font size slider"`
- **A11Y-03: Tracing Canvas Accessibility Status & Stroke Updates**
  - **Target:** `StrokeCanvasView` and `CharacterDetailView`.
  - **Test:** Verify the tracing canvas exposes an accessibility label (`"Tracing canvas for <hanzi>"`) and updates its accessibility value as strokes progress (`"Stroke 1 of 10"`, `"Stroke 2 of 10"`, and `"Completed"` when all strokes finish).

### 3.2 Visual & Color Contrast (WCAG 2.1 AA Compliance)
- **A11Y-04: WCAG 2.1 AA Contrast Ratio Verification**
  - **Target:** App color palette (`ColorExtensions`, `CharacterCellView`, `CharacterDetailView`, `StrokeCanvasView`).
  - **Test:** Calculate relative luminance and contrast ratio for primary text (`Color(white: 0.12)` on `.white`), secondary text (`Color(white: 0.42)` on `.white` and `Color.appBackground`), meaning subtitle, and traced strokes, asserting a minimum `4.5:1` ratio for text and `3.0:1` for graphical UI components.
- **A11Y-05: Color Independence on Stroke & Character Completion**
  - **Target:** `CharacterDetailView` and `StrokeCanvasView`.
  - **Test:** Verify completion states provide non-color feedback: text status change (`"Completed! Resetting..."`), checkmark icon (`checkmark.seal.fill`), haptic feedback, and audio playback.

### 3.3 Dynamic Type, Touch Targets & Reduced Motion
- **A11Y-06: Minimum Touch Target Size (44x44 points)**
  - **Target:** `CharacterCellView`, `CharacterGridView`, and `CharacterDetailView` (`"Trace Next"`, `"Erase and Repeat"`, toolbar buttons, control bar buttons).
  - **Test:** In XCUITest, verify interactive buttons meet the minimum `44x44 pt` hit target area.
- **A11Y-07: Dynamic Type Scaling Support**
  - **Target:** `CharacterGridView`, `CharacterDetailView`, `AboutView`, `LegalView`.
  - **Test:** Launch app with accessibility Dynamic Type sizing and verify secondary labels, navigation headers, and controls remain visible and hittable without layout failure.
- **A11Y-08: Reduced Motion Support (`accessibilityReduceMotion`)**
  - **Target:** `StrokeCanvasView` and `CharacterDetailView`.
  - **Test:** When `accessibilityReduceMotion` (or reduced motion mode) is active, disable looping animated stroke path drawing and immediately display static full-stroke guide paths (`progress = 1.0`).
- **A11Y-09: Orientation & Multitasking Layout Resilience**
  - **Target:** `CharacterGridView` and `CharacterDetailView`.
  - **Test:** Rotate simulator between Portrait and Landscape orientations and verify the character grid, tracing canvas, and action buttons remain visible, non-overlapping, and hittable.
