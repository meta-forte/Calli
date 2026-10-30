import CryptoKit
import MachO
import XCTest
@testable import Calli

final class SecurityAndAccessibilityTests: XCTestCase {

    func testSQLInjectionResilienceInPracticeStorage() {
        let tempDir = NSTemporaryDirectory()
        let dbPath = (tempDir as NSString).appendingPathComponent("sec_sqli_\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(atPath: dbPath) }

        let storage = PracticeStorageService(databasePath: dbPath)
        let payloads = [
            "'; DROP TABLE practice_log; --",
            "爱' OR '1'='1",
            "\" OR \"\"=\"",
            "爱\0; DELETE FROM practice_log;",
            "UNION SELECT 999999 --"
        ]

        for payload in payloads {
            let recorded = storage.recordPractice(character: payload, date: "2026-10-30'; DROP TABLE practice_log; --")
            XCTAssertEqual(recorded, 1)
            let fetched = storage.getPracticeCount(character: payload, date: "2026-10-30'; DROP TABLE practice_log; --")
            XCTAssertEqual(fetched, 1)
        }

        let normalCount = storage.recordPractice(character: "爱", date: "2026-10-30")
        XCTAssertEqual(normalCount, 1)
        XCTAssertEqual(storage.getTotalPracticeCount(character: "爱"), 1)
    }

    @MainActor
    func testAppStoreURLWhitelistingRejectsMaliciousSchemesAndHosts() {
        let validHTTPS = URL(string: "https://apps.apple.com/app/id6738321000")!
        let validITMS = URL(string: "itms-apps://apps.apple.com/app/id6738321000")!
        XCTAssertTrue(AppUpdateService.isValidAppStoreURL(validHTTPS))
        XCTAssertTrue(AppUpdateService.isValidAppStoreURL(validITMS))

        let invalidURLs = [
            "javascript:alert(1)",
            "file:///etc/passwd",
            "tel://1234567890",
            "http://apps.apple.com/app/id6738321000",
            "https://evil.example.com/app/id6738321000",
            "https://apps.apple.com.evil.com/app/id6738321000",
            "https://apps.apple.com@evil.com/app/id6738321000",
            "data:text/html,<script>alert(1)</script>"
        ]

        for raw in invalidURLs {
            if let url = URL(string: raw) {
                XCTAssertFalse(AppUpdateService.isValidAppStoreURL(url), "Expected \(raw) to be rejected")
            }
        }

        let service = AppUpdateService(currentVersion: "1.0.0")
        service.evaluateUpdate(
            with: AppUpdateInfo(
                latestVersion: "2.0.0",
                appStoreUrl: "javascript:alert(1)"
            )
        )
        XCTAssertEqual(service.appStoreURL?.scheme, "https")
        XCTAssertEqual(service.appStoreURL?.host, "apps.apple.com")
    }

    func testEd25519UpdateSignatureVerificationAcceptsValidAndRejectsTampered() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKeyBase64 = privateKey.publicKey.rawRepresentation.base64EncodedString()

        let payloadDict: [String: Any] = [
            "app_store_url": "https://apps.apple.com/app/id6738321000",
            "force_update": false,
            "latest_version": "1.2.0",
            "min_supported_version": "1.0.0",
            "release_notes": "Signed update",
            "timestamp": 1793361190
        ]

        let canonicalBytes = try JSONSerialization.data(
            withJSONObject: payloadDict,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let signature = try privateKey.signature(for: canonicalBytes)
        let signedEnvelope: [String: Any] = [
            "payload": payloadDict,
            "signature": signature.base64EncodedString()
        ]
        let signedData = try JSONSerialization.data(withJSONObject: signedEnvelope)

        let verifiedInfo = try AppUpdateService.verifySignedPayload(
            data: signedData,
            publicKeyBase64: publicKeyBase64
        )
        XCTAssertEqual(verifiedInfo.latestVersion, "1.2.0")
        XCTAssertEqual(verifiedInfo.forceUpdate, false)

        var tamperedPayload = payloadDict
        tamperedPayload["force_update"] = true
        let tamperedEnvelope: [String: Any] = [
            "payload": tamperedPayload,
            "signature": signature.base64EncodedString()
        ]
        let tamperedData = try JSONSerialization.data(withJSONObject: tamperedEnvelope)

        XCTAssertThrowsError(
            try AppUpdateService.verifySignedPayload(data: tamperedData, publicKeyBase64: publicKeyBase64)
        )

        let rogueKey = Curve25519.Signing.PrivateKey()
        let roguePubKeyBase64 = rogueKey.publicKey.rawRepresentation.base64EncodedString()
        XCTAssertThrowsError(
            try AppUpdateService.verifySignedPayload(data: signedData, publicKeyBase64: roguePubKeyBase64)
        )
    }

    func testMalformedVersionStringsAndFuzzing() {
        let negativeVersion = AppVersion("-1.-2.3")
        XCTAssertEqual(negativeVersion.components, [3])

        let overflowVersion = AppVersion("999999999999999999999999999999.1.0")
        XCTAssertEqual(overflowVersion.components, [1, 0])

        let excessiveComponents = AppVersion("1.2.3.4.5.6.7.8.9.10.11.12")
        XCTAssertEqual(excessiveComponents.components.count, 8)

        let garbageVersion = AppVersion("v1.0-beta;DROP TABLE")
        XCTAssertTrue(garbageVersion < AppVersion("1.0.0"))
    }

    func testSearchAndParserBoundaryFuzzing() {
        let sample = [
            CharacterItem(
                id: 1,
                level: 1,
                hanzi: "爱",
                pinyin: "ài",
                tones: "4",
                meaning: "to love",
                exampleChinese: "真可爱！",
                examplePinyin: "Zhēn kěài!",
                exampleEnglish: "How cute!"
            )
        ]
        let index = CharacterSearchIndex(characters: sample)

        let longQuery = String(repeating: "a", count: 10000)
        XCTAssertTrue(index.search(longQuery).isEmpty)

        let combiningStress = "u" + String(repeating: "\u{0308}\u{0304}", count: 500)
        XCTAssertNil(PinyinSyllable.parse(combiningStress))

        let rtlAndControl = "\u{202E}\u{0000}\u{0007}love\u{202C}"
        _ = index.search(rtlAndControl)

        let malformedSVG = "M NaN Infinity L 1e309 -1e309 Q 100 200 NaN 400 C 1 2 3 4 5 Infinity Z ???"
        let path = StrokePathParser.parse(svgPath: malformedSVG, canvasSize: CGSize(width: 300, height: 300))
        XCTAssertTrue(path.isEmpty)

        let zeroSizePath = StrokePathParser.parse(svgPath: "M 100 100 L 200 200 Z", canvasSize: .zero)
        XCTAssertTrue(zeroSizePath.isEmpty)
    }

    func testUserDefaultsBoundsClamping() {
        let suiteName = "com.ibhatech.hanzislate.security.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(-999, forKey: CharacterStore.selectedLevelStorageKey)
        let storeLow = CharacterStore(defaults: defaults, loadBundledData: false)
        XCTAssertEqual(storeLow.selectedLevel, 1)

        defaults.set(999, forKey: CharacterStore.selectedLevelStorageKey)
        let storeHigh = CharacterStore(defaults: defaults, loadBundledData: false)
        XCTAssertEqual(storeHigh.selectedLevel, 9)

        storeHigh.selectedLevel = 0
        XCTAssertEqual(storeHigh.selectedLevel, 1)
        storeHigh.selectedLevel = 42
        XCTAssertEqual(storeHigh.selectedLevel, 9)
    }

    func testInfoPlistZeroPermissionsAndATSEnforcement() throws {
        let info = Bundle.main.infoDictionary ?? [:]

        let forbiddenPermissionKeys = [
            "NSContactsUsageDescription",
            "NSPhotoLibraryUsageDescription",
            "NSPhotoLibraryAddUsageDescription",
            "NSCameraUsageDescription",
            "NSMicrophoneUsageDescription",
            "NSLocationWhenInUseUsageDescription",
            "NSLocationAlwaysAndWhenInUseUsageDescription",
            "NSLocationAlwaysUsageDescription",
            "NSAppleMusicUsageDescription",
            "NSCalendarsUsageDescription",
            "NSRemindersUsageDescription",
            "NSBluetoothAlwaysUsageDescription",
            "NSUserTrackingUsageDescription",
            "NSMotionUsageDescription",
            "NSSpeechRecognitionUsageDescription"
        ]

        for key in forbiddenPermissionKeys {
            XCTAssertNil(info[key], "Unexpected permission key \(key) present in Info.plist")
        }

        XCTAssertFalse((info["UIFileSharingEnabled"] as? Bool) ?? false)
        XCTAssertFalse((info["LSSupportsOpeningDocumentsInPlace"] as? Bool) ?? false)

        if let ats = info["NSAppTransportSecurity"] as? [String: Any] {
            let allowsArbitraryLoads = (ats["NSAllowsArbitraryLoads"] as? Bool) ?? false
            XCTAssertFalse(allowsArbitraryLoads, "NSAllowsArbitraryLoads must be false")
        }
    }

    func testPrivacyManifestCompliance() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"),
            "PrivacyInfo.xcprivacy must be bundled in the application"
        )
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )

        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, false)
        let trackingDomains = plist["NSPrivacyTrackingDomains"] as? [String]
        XCTAssertEqual(trackingDomains, [])

        let collectedDataTypes = plist["NSPrivacyCollectedDataTypes"] as? [[String: Any]]
        XCTAssertEqual(collectedDataTypes?.count, 0)

        let accessedAPIs = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaultsEntry = accessedAPIs.first {
            ($0["NSPrivacyAccessedAPIType"] as? String) == "NSPrivacyAccessedAPICategoryUserDefaults"
        }
        XCTAssertNotNil(userDefaultsEntry)
        let reasons = userDefaultsEntry?["NSPrivacyAccessedAPITypeReasons"] as? [String] ?? []
        XCTAssertTrue(reasons.contains("CA92.1"))
    }

    func testSandboxIsolationAndDatabaseFileProtection() throws {
        let defaultPath = PracticeStorageService.defaultDatabasePath()
        let documentsURL = try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
        XCTAssertTrue(defaultPath.hasPrefix(documentsURL.path))

        let tempDir = NSTemporaryDirectory()
        let dbPath = (tempDir as NSString).appendingPathComponent("sec_prot_\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(atPath: dbPath) }

        let service = PracticeStorageService(databasePath: dbPath)
        _ = service.recordPractice(character: "爱")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dbPath))

        let attributes = try FileManager.default.attributesOfItem(atPath: dbPath)
        if let protection = attributes[.protectionKey] as? FileProtectionType {
            XCTAssertEqual(protection, .completeUntilFirstUserAuthentication)
        }
    }

    func testNoPrivateKeysOrSecretsLeakedInBundle() throws {
        let resourcePath = try XCTUnwrap(Bundle.main.resourcePath)
        let enumerator = FileManager.default.enumerator(atPath: resourcePath)
        let forbiddenExtensions: Set<String> = ["pem", "p8", "p12", "key", "jks", "keystore", "env"]

        while let relativePath = enumerator?.nextObject() as? String {
            let fileName = (relativePath as NSString).lastPathComponent
            let ext = (fileName as NSString).pathExtension.lowercased()
            XCTAssertFalse(
                forbiddenExtensions.contains(ext),
                "Forbidden secret file bundled in app: \(relativePath)"
            )
            XCTAssertNotEqual(fileName, ".env", "Environment file must not be bundled")
            XCTAssertNotEqual(fileName, "update_signing_key.pem", "Private signing key must not be bundled")
        }
    }

    func testMachOBinaryHardeningFlags() throws {
        let executableURL = try XCTUnwrap(Bundle.main.executableURL)
        let data = try Data(contentsOf: executableURL)
        XCTAssertGreaterThanOrEqual(data.count, MemoryLayout<mach_header_64>.size)

        let header = data.withUnsafeBytes { rawBuffer in
            rawBuffer.load(as: mach_header_64.self)
        }
        XCTAssertEqual(header.magic, MH_MAGIC_64)
        XCTAssertEqual(header.filetype, UInt32(MH_EXECUTE))

        let isPIE = (header.flags & UInt32(MH_PIE)) != 0
        XCTAssertTrue(isPIE, "Main executable must be compiled as Position Independent Executable (MH_PIE)")

        let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
        let stackChkGuard = dlsym(rtldDefault, "__stack_chk_guard")
        let objcRetain = dlsym(rtldDefault, "objc_retain")
        XCTAssertNotNil(stackChkGuard, "Stack canary symbol __stack_chk_guard must be present")
        XCTAssertNotNil(objcRetain, "ARC runtime symbol objc_retain must be present")
    }

    func testCharacterCellVoiceOverAccessibilityLabels() {
        let hskChar = CharacterItem(
            id: 0,
            level: 1,
            hanzi: "爱",
            pinyin: "ài",
            tones: "4",
            meaning: "to love",
            exampleChinese: "真可爱！",
            examplePinyin: "Zhēn kěài!",
            exampleEnglish: "How cute!"
        )
        let label = CharacterCellView.accessibilityDescription(for: hskChar)
        XCTAssertEqual(label, "爱, pinyin ài, meaning to love, HSK Level 1. Double tap to trace.")
        XCTAssertTrue(label.hasPrefix("爱,"))

        let searchLabel = CharacterCellView.accessibilityDescription(for: hskChar, meaningSubtitle: "cherish")
        XCTAssertEqual(searchLabel, "爱, pinyin ài, meaning cherish, HSK Level 1. Double tap to trace.")

        let otherChar = CharacterItem(
            id: 9000,
            level: 0,
            hanzi: "龍",
            pinyin: "lóng",
            tones: "2",
            meaning: "dragon",
            exampleChinese: "",
            examplePinyin: "",
            exampleEnglish: ""
        )
        let otherLabel = CharacterCellView.accessibilityDescription(for: otherChar)
        XCTAssertEqual(otherLabel, "龍, pinyin lóng, meaning dragon, Other Character. Double tap to trace.")
    }

    func testTracingCanvasVoiceOverStatusAndReducedMotion() {
        XCTAssertEqual(
            StrokeCanvasView.strokeStatusDescription(currentStrokeIndex: 0, totalStrokes: 10, isCompleted: false),
            "Stroke 1 of 10"
        )
        XCTAssertEqual(
            StrokeCanvasView.strokeStatusDescription(currentStrokeIndex: 4, totalStrokes: 10, isCompleted: false),
            "Stroke 5 of 10"
        )
        XCTAssertEqual(
            StrokeCanvasView.strokeStatusDescription(currentStrokeIndex: 9, totalStrokes: 10, isCompleted: true),
            "Completed all 10 strokes"
        )

        let strokeInfo = CharacterStrokeInfo(
            strokes: ["M 0 0 L 100 100", "M 10 10 L 200 200", "M 20 20 L 300 300"],
            medians: [[[0, 0], [100, 100]], [[10, 10], [200, 200]], [[20, 20], [300, 300]]]
        )
        let singleProgress = StrokeCanvasView.reducedMotionProgresses(
            for: strokeInfo,
            currentStrokeIndex: 1,
            mode: .single
        )
        XCTAssertEqual(singleProgress, [1: 1.0])

        let pairwiseProgress = StrokeCanvasView.reducedMotionProgresses(
            for: strokeInfo,
            currentStrokeIndex: 0,
            mode: .pairwise
        )
        XCTAssertEqual(pairwiseProgress, [0: 1.0, 1: 1.0])
    }

    func testWCAGColorContrastCompliance() {
        let primaryOnWhite = WCAGContrastCalculator.contrastRatio(foregroundWhite: 0.12, backgroundWhite: 1.0)
        XCTAssertGreaterThanOrEqual(primaryOnWhite, 4.5, "Primary text on white must meet WCAG AA 4.5:1")

        let secondaryOnWhite = WCAGContrastCalculator.contrastRatio(foregroundWhite: 0.42, backgroundWhite: 1.0)
        XCTAssertGreaterThanOrEqual(secondaryOnWhite, 4.5, "Secondary text on white must meet WCAG AA 4.5:1")

        let secondaryOnAppBg = WCAGContrastCalculator.contrastRatio(
            foreground: (0.42, 0.42, 0.42),
            background: (239.0 / 255.0, 239.0 / 255.0, 239.0 / 255.0)
        )
        XCTAssertGreaterThanOrEqual(secondaryOnAppBg, 4.5, "Secondary text on appBackground must meet WCAG AA 4.5:1")

        let accessibleBlueOnWhite = WCAGContrastCalculator.contrastRatio(
            foreground: (0.0, 0.35, 0.78),
            background: (1.0, 1.0, 1.0)
        )
        XCTAssertGreaterThanOrEqual(accessibleBlueOnWhite, 4.5, "Meaning subtitle blue on white must meet WCAG AA 4.5:1")

        let userTraceOnCanvas = WCAGContrastCalculator.contrastRatio(foregroundWhite: 0.0, backgroundWhite: 1.0)
        XCTAssertEqual(userTraceOnCanvas, 21.0, accuracy: 0.1)
    }
}
