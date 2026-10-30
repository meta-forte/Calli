# Secure App Update Verification, TLS Standards, and Local Mock Server Spec

## 1. TLS 1.2 vs. TLS 1.3 Clarification

### Is TLS 1.3 Decommissioned?
**No. TLS 1.3 is NOT decommissioned.** It is the current, active, and most secure standard for Internet transport security (defined by the IETF in [RFC 8446](https://datatracker.ietf.org/doc/html/rfc8446)).

### What Was Actually Decommissioned?
- **TLS 1.0 and TLS 1.1** were officially deprecated and decommissioned by the IETF in March 2021 via [RFC 8996](https://datatracker.ietf.org/doc/html/rfc8996) due to vulnerabilities (e.g., BEAST, POODLE, weak SHA-1/MD5 handshakes, lack of forward secrecy).
- Major platforms (Apple iOS, macOS, Android, Google Chrome, Mozilla Firefox, Safari) disabled TLS 1.0 and 1.1 completely.
- **TLS 1.2** (RFC 5246) remains supported across all devices as a fallback.
- **TLS 1.3** is the recommended industry standard because:
  1. Handshake latency is cut in half (1-RTT round-trip instead of 2-RTT).
  2. All obsolete and broken ciphers were removed (no RC4, no CBC mode, no static RSA key exchange).
  3. Perfect Forward Secrecy (PFS) is strictly mandatory.

---

## 2. Local Development: HTTP vs. Self-Signed HTTPS

When testing locally on an iOS simulator or physical device, two approaches exist:

### Approach A (Recommended): HTTP with Apple App Transport Security (ATS) Local Exceptions
Apple's App Transport Security (ATS) permits local networking over HTTP without compromising production security. In `Calli/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

- **Why this is best**:
  - `NSAllowsLocalNetworking` automatically allows connections to `localhost`, `127.0.0.1`, and local LAN IPs (e.g., `192.168.x.x` for phone testing) over HTTP.
  - Production external URLs (like Firebase Hosting or App Store) remain strictly enforced under HTTPS.
  - No custom certificate installation or profile provisioning is needed on the phone or simulator.

### Approach B: Local HTTPS with a Self-Signed Certificate
Running a local HTTPS server with a self-signed certificate requires:
1. Creating a custom Certificate Authority (CA) and leaf certificate.
2. Manually air-dropping the `.crt` to the physical iPhone, installing the profile in iOS Settings, and enabling "Full Trust for Root Certificates" under Settings > General > About > Certificate Trust Settings.
3. Or writing custom `URLSessionDelegate` code that disables TLS validation (a dangerous pattern that risks leaking into production builds).

### The True MITM Defense: Application-Layer Cryptographic Signing
By signing the `version.json` payload with an **Ed25519 digital signature**, the update mechanism does not rely exclusively on TLS. Even over plain HTTP on a local network, a rogue actor or proxy cannot forge or alter the version data without invalidating the cryptographic signature.

---

## 3. Cryptographic Key Generation and Version Signing

### A. Algorithm Selection: Ed25519 (Curve25519)
- **Why Ed25519?**
  - Ultra-fast verification and signing.
  - Tiny keys (32 bytes public key, 64 bytes signature).
  - Immune to side-channel timing attacks.
  - Natively supported in iOS 13+ via Apple's `CryptoKit` (`Curve25519.Signing`).
  - Natively supported in Python via the `cryptography` package.

### B. Generating Keys
Run the provided Python script:
```bash
./venv/bin/python scripts/update_server.py generate-keys
```

This generates:
- Private Key (PEM format): `./tmp/update_signing_key.pem` (kept secure on your release machine / CI).
- Public Key (Base64 string): `./tmp/update_public_key.b64` (embedded inside Calli's `AppConfig.properties` or Swift code).

### C. Signing a Version Release
```bash
./venv/bin/python scripts/update_server.py sign \
  --version "1.1.0" \
  --min-version "1.0.0" \
  --notes "Added stroke practice and audio improvements." \
  --url "https://apps.apple.com/app/id6738321000"
```

Output `version.json`:
```json
{
  "payload": {
    "latest_version": "1.1.0",
    "min_supported_version": "1.0.0",
    "release_notes": "Added stroke practice and audio improvements.",
    "app_store_url": "https://apps.apple.com/app/id6738321000",
    "force_update": false,
    "timestamp": 1793361190
  },
  "signature": "ZaUtZhR5B88rteYt2DABNPu9+p6+GN9JlgA43yU97HsS9BL1Me20qk79GB35IiGNDvzh8udGNioP6HR/8e3nCg=="
}
```

---

## 4. Local Test Server (`scripts/update_server.py`)

A standalone mock server is located at `scripts/update_server.py`.

### Commands
- Launch default server (returns v1.1.0 optional update):
  ```bash
  ./venv/bin/python scripts/update_server.py serve --port 8000
  ```
- Launch forced update server (returns v2.0.0 forced update):
  ```bash
  ./venv/bin/python scripts/update_server.py serve --port 8000 --mode forced
  ```
- Launch up-to-date server (returns v1.0.0):
  ```bash
  ./venv/bin/python scripts/update_server.py serve --port 8000 --mode uptodate
  ```

### Endpoints
- `GET /version.json`: Returns the signed payload according to active mode.
- `GET /up-to-date`: Explicitly returns signed payload with version matching current app (v1.0.0).
- `GET /force-update`: Explicitly returns signed payload with forced update (v2.0.0).
- `GET /health`: Returns `{"status": "ok"}` for readiness probes.

---

## 5. Required Swift Client Code Changes

To integrate signature verification and URL whitelisting into [`AppUpdateService.swift`](file:///Users/manas/dev/Calli/Calli/Sources/Services/AppUpdateService.swift):

### 1. Bundle Public Key
In `AppConfig.properties`:
```properties
update_public_key=fn7QTmqSxeic+1i7wCXf+hZiKWKwSyg0kiiG8HG4VZM=
```

### 2. Verify Payload in Swift with CryptoKit
```swift
import CryptoKit

struct SignedVersionResponse: Decodable {
    let payload: AppUpdateInfo
    let signature: String
}

func verifyAndDecode(data: Data, publicKeyBase64: String) throws -> AppUpdateInfo {
    let signedResponse = try JSONDecoder().decode(SignedVersionResponse.self, from: data)

    guard let pubKeyData = Data(base64Encoded: publicKeyBase64),
          let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: pubKeyData),
          let signatureData = Data(base64Encoded: signedResponse.signature) else {
        throw URLError(.cannotDecodeContentData)
    }

    let payloadJson = try JSONEncoder().encode(signedResponse.payload)
    guard publicKey.isValidSignature(signatureData, for: payloadJson) else {
        throw URLError(.secureConnectionFailed)
    }

    return signedResponse.payload
}
```

### 3. App Store URL Whitelisting
To prevent a MITM attacker from pointing users to a malicious phishing page:
```swift
func isValidAppStoreURL(_ url: URL) -> Bool {
    guard url.scheme == "https",
          url.host == "apps.apple.com",
          url.path.hasPrefix("/app/") else {
        return false
    }
    return true
}
```

---

## 6. End-to-End Release Workflow & Artifacts

### A. Is Signing the Version Release a Manual Activity?
It can be run manually via CLI during initial development, but in a production setup it should be **automated inside your CI/CD pipeline**.

However, **the timing of publishing `version.json` must be sequenced with store approval**:
1. You do **not** publish the updated `version.json` when building the binaries.
2. You only publish the updated `version.json` to Firebase **after** Apple App Store and Google Play have approved and released the new version to public users.
3. If you publish `version.json` prematurely, existing users who open the app will receive an "Update Available" notification and be directed to the App Store, where the new version is not yet downloadable.

### B. Complete Step-by-Step Release Lifecycle

```text
Step 1: Code & Version Bump
   - Increment MARKETING_VERSION and CURRENT_PROJECT_VERSION in project.yml / AppStoreMetadata.properties.
   - Commit and tag the release (e.g., git tag v1.1.0).
       │
       ▼
Step 2: Build & Sign Store Artifacts
   - iOS: Build .xcarchive and export a signed .ipa (iOS App Store Package).
   - Android: Build Gradle task bundleRelease to generate a signed .aab (Android App Bundle).
       │
       ▼
Step 3: Upload Artifacts to Developer Portals
   - iOS: Upload .ipa to App Store Connect (via altool, xcrun notarytool, or Fastlane).
   - Android: Upload .aab to Google Play Console (via Play Developer API or Fastlane).
       │
       ▼
Step 4: Store Review & Publication Window
   - Apple App Review and Google Play Review evaluate the submission (typically 12 to 48 hours).
   - Once approved, the releases are set to "Live / Published".
       │
       ▼
Step 5: Sign & Deploy version.json
   - Execute: ./venv/bin/python scripts/update_server.py sign --version "1.1.0" ...
   - Deploy signed version.json to Firebase: firebase deploy --only hosting
       │
       ▼
Step 6: In-App Discovery
   - Active user apps query Firebase, verify the Ed25519 signature, and display the update alert.
```

---

## 7. Automating the Release Pipeline with GitLab CI/CD

Can this process be automated end-to-end? **Yes.**

### A. Runner Requirement: macOS Runner
Because Apple's compilation tools (`xcodebuild`, `altool`, `codesign`) require macOS, your GitLab CI pipeline requires a **macOS runner**.
- **Option 1 (Recommended & Free)**: Register your own MacBook as a self-hosted GitLab Runner (`gitlab-runner exec` or daemon). Your MacBook already has Xcode, SDKs, Android Studio, and local developer certificates installed.
- **Option 2**: Use GitLab SaaS macOS Cloud Runners.

### B. Automation Tool: Fastlane
Fastlane is the industry-standard CLI automation tool that wraps `xcodebuild` and Gradle:
- `fastlane ios release`: Builds `.xcarchive`, signs `.ipa`, uploads to App Store Connect, and manages metadata.
- `fastlane android release`: Builds `.aab`, signs with release keystore, and uploads to Google Play tracks.

### C. Example `.gitlab-ci.yml` Pipeline Architecture

```yaml
stages:
  - test
  - build_and_upload
  - publish_update_notice

test_suite:
  stage: test
  tags:
    - macos
  script:
    - xcodebuild test -project Calli.xcodeproj -scheme Calli -destination "platform=iOS Simulator,name=iPhone 17"

build_and_upload_stores:
  stage: build_and_upload
  tags:
    - macos
  only:
    - tags
  script:
    - fastlane ios release
    - fastlane android release

publish_version_json:
  stage: publish_update_notice
  tags:
    - macos
  when: manual
  only:
    - tags
  script:
    - ./venv/bin/python scripts/update_server.py sign --version "$CI_COMMIT_TAG"
    - firebase deploy --only hosting --token "$FIREBASE_TOKEN"
```

Notice `when: manual` for `publish_version_json`: Once you receive the email from Apple/Google that the build is approved and live in the store, you click the "Play" button on this stage in GitLab to instantly sign and deploy `version.json` to Firebase.

---

## 8. Secrets and Private Key Management

### A. What Secrets Exist in the Project?
1. **Apple Distribution Signing**: `.p12` Certificate and Provisioning Profile.
2. **Android Keystore**: `release.keystore` / `upload-keystore.jks` and keystore password.
3. **Ed25519 Version Signing Key**: `update_signing_key.pem` (used to generate signatures for `version.json`).
4. **App Store Connect API Key**: `AuthKey_XXXXXXXXXX.p8` (for automated uploading without 2FA prompts).
5. **Google Play Service Account**: `play-console-api.json`.
6. **Firebase Token / Credentials**: For automated `firebase deploy`.

### B. Where Should You Store Them?

| Solution | Verdict | Why / When to Use |
|---|---|---|
| **Local HashiCorp Vault** | **Not Recommended** | Excessive operational overhead. Requires provisioning, unsealing on restart, backup maintenance, and high availability configuration for a single developer setup. |
| **AWS Secrets Manager / KMS** | **Viable if already on AWS** | Secure, but incurs recurring monthly cost ($0.40/secret/month + API call fees) and introduces AWS IAM dependencies for a project hosted on Firebase. |
| **1Password / 1Password Developer CLI (`op`)** | **Strong for Local Dev** | Excellent for local developer workstations. Keeps `.p12`, `.pem`, and passwords encrypted, unlocked biographically via Touch ID, and injected into shell scripts on demand via `op run`. |
| **GitLab CI/CD Masked & Protected Variables + Fastlane Match** | **Industry Standard for CI/CD** | Zero extra cost, built natively into your repository. Variables are restricted exclusively to protected branches (`main`) and protected tags (`v*`). Non-maintainers or feature branches cannot read or print them. |

### C. Recommended Strategy:
1. **For Local Workstation**: Store the master `.pem`, `.p12`, and keystores in **1Password** or your encrypted macOS Keychain.
2. **For Automated CI/CD**: Store the Base64-encoded strings of the keys as **GitLab Protected & Masked CI Variables** (`APP_STORE_API_KEY`, `UPDATE_SIGNING_KEY_PEM`, `ANDROID_KEYSTORE_BASE64`). During the CI job, the runner writes them to a temporary memory-backed file (`/dev/shm` or `./tmp`), executes the signing command, and immediately shreds the file.

---

## 9. Extending to Android on the Same MacBook

### Can You Use the Same MacBook to Generate the Android Binary?
**Yes, 100%.**
A MacBook is the universal development workstation for mobile engineering:
- macOS can compile **both iOS (`.ipa`) and Android (`.aab` / `.apk`)** natively.
- Windows and Linux cannot compile iOS applications (because Xcode and the iOS SDK only run on macOS).

### Android Toolchain Setup on macOS:
1. Install **Android Studio** or Android Command Line Tools (`brew install --cask android-studio`).
2. Install **JDK 17** (`brew install openjdk@17`).
3. Set environment variables in your shell profile (`~/.zshrc`):
   ```bash
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
   ```
4. Build commands:
   - To build an **AAB** for Google Play: `./gradlew bundleRelease`
   - To build a direct **APK** for local Android phone testing: `./gradlew assembleRelease`
   - Sign the binary: `apksigner sign --ks release.jks --ks-key-alias my-key app-release.aab`

---

## 10. Managing App Permissions & Store Privacy Declarations

### A. Current Status of Calli / HanziSlate
HanziSlate operates as an offline-first educational tool. It does **not** access:
- User contacts or address book
- Photos, media library, or camera
- Location / GPS
- Microphone
- Device external file folders outside its own sandbox

### B. In-Binary Declaration: How Permissions Are Declared in Code

#### 1. iOS (`Calli/Info.plist`)
Apple enforces an explicit **opt-in whitelist security model**:
- In iOS, if an app does not need Camera, Contacts, Photos, or Location, **you simply omit the corresponding `NS...UsageDescription` keys** (e.g., `NSCameraUsageDescription`, `NSContactsUsageDescription`).
- **Enforcement by iOS Sandbox**: Because these keys are absent, the iOS operating system physically blocks the application from calling contacts or photos APIs. If the app attempted to access them without the declared key, iOS would terminate the app process immediately with a crash report.
- The app only accesses its own dedicated private directory container (`Documents/` and `Library/Application Support/`), which does not require any permission prompt.

#### 2. Android (`AndroidManifest.xml`)
- In Android, permissions must be explicitly requested via `<uses-permission>` tags.
- For HanziSlate, the only permission required is:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```
  This is a "Normal" permission (not a "Dangerous" runtime permission). It does not trigger a user pop-up, but allows the app to check the update server and stream optional audio if not bundled locally.
- Do **not** declare `READ_EXTERNAL_STORAGE` or `READ_CONTACTS`.

---

### C. In-Store Declarations: App Store & Google Play

Both Apple and Google require developers to declare their data handling practices in the store console before publishing.

#### 1. Apple App Store Connect: App Privacy (Nutrition Label)
Under **App Store Connect > Your App > App Privacy**:
1. When asked: *"Do you or your third-party partners collect data from this app?"*
2. Select: **"No, we do not collect data from this app."**
3. Result on the App Store product page:
   - Apple displays the verified blue shield badge:
   - **"Data Not Collected: The developer does not collect any data from this app."**

#### 2. Google Play Console: Data Safety Form
Under **Google Play Console > App Content > Data safety**:
1. When asked: *"Does your app collect or share any of the required user data types?"*
2. Select: **"No"**.
3. Result on the Play Store product page:
   - Displays: *"No data shared with third parties"*, *"No data collected"*, and *"Data is encrypted in transit"*.

---

## 11. Multi-Track Distribution: Beta Testing, Insiders, and A/B Testing Architecture

### A. Can You Have Two Instances of the App on iOS & Android?

#### 1. In-Store Discovery & Installation Models
There are two ways to achieve this, depending on user experience requirements:

| Model | How It Works | Can Both Be Installed Side-by-Side? | Store Setup Required |
|---|---|---|---|
| **Model 1: TestFlight Public Link (Standard)** | Single App Record in App Store Connect. Testers click a link (`testflight.apple.com/join/XYZ`) and install beta builds via Apple's TestFlight app. | **No** (TestFlight build replaces the App Store build). | 1 App Record. |
| **Model 2: Dual App / Insiders Model (VS Code Insiders style)** | Separate App Record with distinct Bundle ID (`com.ibhatech.hanzislate.beta`). Dedicated "HanziSlate Beta" app. | **Yes** (Both production and beta apps coexist side-by-side on the same phone). | 2 App Records. |

#### 2. Recommendation:
- If your testers only need to test upcoming features and don't need both versions running simultaneously: **Model 1 (TestFlight Public Link)** is easiest, zero extra bundle ID management, and completely free.
- If testers (e.g. power users / Insiders) must keep their production app and practice streaks intact while experimenting with beta features: **Model 2 (Dual Bundle IDs)** is required.

---

### B. Managing Multiple Test Builds: Beta-A, Beta-B, and Production

Both Apple App Store Connect and Google Play Console provide built-in multi-track mechanisms to manage concurrent builds:

```text
                                  ┌────────────────────────┐
                                  │   Codebase (Git Repo)  │
                                  └───────────┬────────────┘
                                              │
                      ┌───────────────────────┼───────────────────────┐
                      ▼                       ▼                       ▼
              ┌───────────────┐       ┌───────────────┐       ┌───────────────┐
              │ Build: Beta-A │       │ Build: Beta-B │       │ Build: Prod   │
              │ (Feature Set 1│       │ (Feature Set 2│       │ (Stable v1.0) │
              └───────┬───────┘       └───────┬───────┘       └───────┬───────┘
                      │                       │                       │
      ┌───────────────┴───────────────┐       │                       │
      ▼                               ▼       ▼                       ▼
App Store Connect:              Google Play Console:            Production Stores:
- TestFlight Group "Beta-A"     - Closed Track "Beta-A"        - App Store Public
  (Public Link A)                 (Testers list A)             - Play Store Public
- TestFlight Group "Beta-B"     - Closed Track "Beta-B"          (Phased Rollout:
  (Public Link B)                 (Testers list B)               1% -> 20% -> 100%)
```

#### 1. On Apple (App Store Connect & TestFlight):
- You upload multiple builds with incrementing build numbers (e.g., Version `1.1.0` Build `101` and Build `102`).
- In **TestFlight > External Groups**, create separate testing groups:
  - **Group "Cohort-A"**: Assigned Build `101`. Generates Public Link A.
  - **Group "Cohort-B"**: Assigned Build `102`. Generates Public Link B.
- Testers joining via Link A automatically receive Build 101, while Link B testers receive Build 102.
- The Production release remains unchanged on the public App Store.

#### 2. On Google Play (Play Console):
Google Play natively separates release channels into parallel tracks:
- **Internal Testing**: Instant deployment (no review) for up to 100 internal developers.
- **Closed Testing (Alpha/Beta)**: You can create unlimited custom tracks (e.g., Track `beta-a` and Track `beta-b`). Each track has its own opt-in URL and tester email list.
- **Open Testing**: Public beta page visible on the Play Store.
- **Production Track**: Public release, supporting **Staged Rollouts** (e.g., release to 5% of users on Day 1, 20% on Day 2, 100% on Day 5).

---

### C. A/B Testing on Mobile: Real-Time Users vs. Beta Cohorts

There are 3 distinct layers of A/B testing on mobile devices:

#### Layer 1: In-App Feature & UX A/B Testing (Firebase Remote Config)
This is the most powerful method because it requires **no new binary uploads** or app store reviews:
- Integrated via Firebase Remote Config & Firebase A/B Testing (already aligned with Calli's Firebase stack).
- **How it works**:
  1. Define a parameter in code, e.g., `stroke_hint_delay: Double` or `tracing_algorithm: String`.
  2. In Firebase Console, create an A/B Test experiment:
     - **Variant A (Control - 50%)**: `stroke_hint_delay = 5.0`
     - **Variant B (Treatment - 50%)**: `stroke_hint_delay = 2.5`
  3. Firebase assigns users randomly or targets a predefined subset (e.g. users where `app_version` contains "beta" or custom user property `is_insider == true`).
  4. Firebase automatically tracks retention, session duration, and goal completions (e.g. daily character repetitions).

#### Layer 2: Build-Level A/B Testing (TestFlight & Play Tracks)
- Used when testing large architectural changes or new frameworks that cannot be toggled with a simple flag.
- Distribute Build Beta-A to Cohort A and Build Beta-B to Cohort B via separate TestFlight groups or Google Play closed tracks.

#### Layer 3: Store Discovery A/B Testing (App Store PPO & Play Store Experiments)
- Tests App Store and Play Store conversion rates before users even download the app:
  - **Apple Product Page Optimization (PPO)**: Test up to 3 treatments (icons, screenshots, preview videos) against the original on live App Store search visitors.
  - **Google Play Store Listing Experiments**: Test icon variants, promo banners, and descriptions across percentages of store traffic.

---

### D. Xcode Project Configuration for Dual-Target (Side-by-Side) Setup

If you adopt the VS Code Insiders model (allowing `HanziSlate` and `HanziSlate Beta` to be installed on the same iPhone simultaneously), configure [project.yml](file:///Users/manas/dev/Calli/project.yml) with distinct bundle identifiers and display names:

```yaml
targets:
  Calli:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Calli/Sources
      - path: Calli/Resources
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.ibhatech.hanzislate
      INFOPLIST_KEY_CFBundleDisplayName: "HanziSlate"
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon

  CalliBeta:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Calli/Sources
      - path: Calli/Resources
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.ibhatech.hanzislate.beta
      INFOPLIST_KEY_CFBundleDisplayName: "HanziSlate Beta"
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIconBeta
```

This configuration ensures:
1. Both apps have separate sandbox storage on iOS (separate user defaults and databases).
2. The Beta icon can display a visible "BETA" badge.
3. TestFlight manages them as two independent apps with their own public invite links.


