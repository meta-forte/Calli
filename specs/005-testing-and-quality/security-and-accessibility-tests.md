# App Security and Accessibility Testing Specification

## 1. App Security Testing Plan

### 1.1 Network & Transport Security
- **App Transport Security (ATS):** Ensure `NSAppTransportSecurity` enforces strict HTTPS (TLS 1.3/1.2). No arbitrary loads or cleartext HTTP requests.
- **Offline Integrity:** All core assets (character lists, stroke vectors, bundled audio) must load securely from the local application bundle without external network dependencies.
- **Asset Origin Validation:** If any remote audio/data sync is introduced later, enforce SSL certificate pinning and cryptographic hash verification.

### 1.2 Data at Rest & Storage Security
- **Sandbox Compliance:** App data must remain strictly isolated within the iOS app container sandbox.
- **Keychain vs. UserDefaults:**
  - `UserDefaults` must only store non-sensitive user preferences (e.g., selected HSK level, font size slider value, dark mode preference).
  - No personal identifiable information (PII) or authentication tokens may be logged or saved in plaintext.
- **Data Protection:** Enable standard file protection (`NSFileProtectionCompleteUntilFirstUserAuthentication`).

### 1.3 Binary & Dependency Hardening
- **Compiler Flags:** Verify Position Independent Executable (PIE), Automatic Reference Counting (ARC), and Stack Canaries (`-fstack-protector-all`) are enabled.
- **Dependency Audit:** Audit third-party packages for known vulnerabilities (CVEs) and outdated licenses.
- **Apple Privacy Manifest Compliance:** Include `PrivacyInfo.xcprivacy` declaring:
  - Zero third-party tracking domains.
  - Zero user data collection linked to identity.
  - Standard required-reason APIs (e.g., UserDefaults access under reason `CA92.1`).

---

## 2. Accessibility (a11y) Testing Plan

### 2.1 VoiceOver & Screen Readers
- **Hanzi Character Cell:** Each grid cell must provide an informative accessibility label:
  - *Example:* `"Character 爱, pinyin ài, meaning to love, HSK Level 1. Double tap to trace."`
  - Traits: `.isButton`
- **Tracing Canvas:** Provide VoiceOver status updates when tracing strokes:
  - *Example:* `"Stroke 1 of 10 completed. Trace stroke 2: horizontal stroke left to right."`
- **Audio Button:** Labeled `"Play pronunciation audio"`, trait `.isButton`.

### 2.2 Visual & Color Contrast (WCAG 2.1 AA Compliance)
- **Minimum Contrast Ratio:** Text, stroke outlines, and grid guidelines must maintain at least a **4.5:1** contrast ratio against the background in both Light Mode and Dark Mode.
- **Color Independence:** Stroke tracing feedback must not rely solely on color (e.g., red/green). Combine color changes with haptic feedback (tactile tap) and sound cues.

### 2.3 Dynamic Type & Text Scaling
- Support Apple's Dynamic Type system across all secondary text elements (Pinyin labels, translations, menu titles).
- Elements must gracefully expand without clipping text or dropping below minimum readable contrast.

### 2.4 Motor & Touch Target Guidelines
- **Minimum Tap Target:** Every interactive character cell, button, and slider thumb must measure at least **44x44 points** (iOS HIG) and **48x48 dp** (Android Material).
- **Reduced Motion Support:** Respect the system-wide `accessibilityReduceMotion` setting. If enabled, disable animated stroke path drawing loops and show static step-by-step progressions.

### 2.5 iPad Multitasking & Orientation
- Seamless UI layout support across Portrait, Landscape, Split View (1/3, 1/2, 2/3), Slide Over, and Stage Manager without crashing or layout distortion.
