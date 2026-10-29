import XCTest
@testable import Calli

final class AppUpdateServiceTests: XCTestCase {

    func testAppVersionComparison() {
        XCTAssertTrue(AppVersion("1.0.0") < AppVersion("1.0.1"))
        XCTAssertTrue(AppVersion("1.0") < AppVersion("1.0.1"))
        XCTAssertTrue(AppVersion("1.0.0") < AppVersion("2.0.0"))
        XCTAssertTrue(AppVersion("1.9.9") < AppVersion("1.10.0"))
        XCTAssertFalse(AppVersion("2.0.0") < AppVersion("1.9.9"))
        XCTAssertFalse(AppVersion("1.0.0") < AppVersion("1.0.0"))
        XCTAssertFalse(AppVersion("1.0") < AppVersion("1.0.0"))
    }

    func testPropertyConfigParsing() {
        let content = """
        # Sample configuration
        update_check_url=http://localhost:8000/version.json
        app_store_url=https://apps.apple.com/app/id123456
        ! another comment
        key_with_spaces =  value with spaces 
        """
        let properties = PropertyConfig.parse(content: content)
        XCTAssertEqual(properties["update_check_url"], "http://localhost:8000/version.json")
        XCTAssertEqual(properties["app_store_url"], "https://apps.apple.com/app/id123456")
        XCTAssertEqual(properties["key_with_spaces"], "value with spaces")
    }

    func testAppUpdateInfoDecodingSnakeCase() throws {
        let json = """
        {
            "latest_version": "1.2.0",
            "min_supported_version": "1.0.1",
            "release_notes": "Bug fixes and improvements",
            "app_store_url": "https://apps.apple.com/app/id999",
            "force_update": false
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(AppUpdateInfo.self, from: json)
        XCTAssertEqual(info.latestVersion, "1.2.0")
        XCTAssertEqual(info.minSupportedVersion, "1.0.1")
        XCTAssertEqual(info.releaseNotes, "Bug fixes and improvements")
        XCTAssertEqual(info.appStoreUrl, "https://apps.apple.com/app/id999")
        XCTAssertEqual(info.forceUpdate, false)
    }

    func testAppUpdateInfoDecodingCamelCase() throws {
        let json = """
        {
            "latestVersion": "2.0.0",
            "minSupportedVersion": "1.5.0",
            "releaseNotes": "Major update",
            "appStoreUrl": "https://apps.apple.com/app/id888",
            "forceUpdate": true
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(AppUpdateInfo.self, from: json)
        XCTAssertEqual(info.latestVersion, "2.0.0")
        XCTAssertEqual(info.minSupportedVersion, "1.5.0")
        XCTAssertEqual(info.releaseNotes, "Major update")
        XCTAssertEqual(info.appStoreUrl, "https://apps.apple.com/app/id888")
        XCTAssertEqual(info.forceUpdate, true)
    }

    @MainActor
    func testForcedUpdateEvaluationWhenBelowMinimum() {
        let service = AppUpdateService(currentVersion: "1.0.0")
        let info = AppUpdateInfo(
            latestVersion: "1.2.0",
            minSupportedVersion: "1.1.0",
            releaseNotes: "Critical security patch",
            appStoreUrl: "https://apps.apple.com",
            forceUpdate: false
        )

        service.evaluateUpdate(with: info)

        XCTAssertTrue(service.isForcedUpdate)
        XCTAssertFalse(service.isOptionalUpdate)
        XCTAssertTrue(service.hasUnreadUpdate)
    }

    @MainActor
    func testForcedUpdateEvaluationWhenForceFlagIsTrue() {
        let service = AppUpdateService(currentVersion: "1.0.0")
        let info = AppUpdateInfo(
            latestVersion: "1.1.0",
            minSupportedVersion: "1.0.0",
            releaseNotes: "Forced update",
            appStoreUrl: "https://apps.apple.com",
            forceUpdate: true
        )

        service.evaluateUpdate(with: info)

        XCTAssertTrue(service.isForcedUpdate)
        XCTAssertFalse(service.isOptionalUpdate)
        XCTAssertTrue(service.hasUnreadUpdate)
    }

    @MainActor
    func testOptionalUpdateEvaluation() {
        let service = AppUpdateService(currentVersion: "1.0.0")
        let info = AppUpdateInfo(
            latestVersion: "1.1.0",
            minSupportedVersion: "1.0.0",
            releaseNotes: "New Hanzi practice characters",
            appStoreUrl: "https://apps.apple.com",
            forceUpdate: false
        )

        service.evaluateUpdate(with: info)

        XCTAssertFalse(service.isForcedUpdate)
        XCTAssertTrue(service.isOptionalUpdate)
        XCTAssertTrue(service.hasUnreadUpdate)

        service.dismissOptionalNotice()
        XCTAssertFalse(service.hasUnreadUpdate)
    }

    @MainActor
    func testNoUpdateWhenCurrentIsSameOrHigher() {
        let service = AppUpdateService(currentVersion: "1.2.0")
        let info = AppUpdateInfo(
            latestVersion: "1.2.0",
            minSupportedVersion: "1.0.0"
        )

        service.evaluateUpdate(with: info)

        XCTAssertFalse(service.isForcedUpdate)
        XCTAssertFalse(service.isOptionalUpdate)
        XCTAssertFalse(service.hasUnreadUpdate)
    }

    @MainActor
    func testAppStoreUrlOpen() {
        let service = AppUpdateService(currentVersion: "1.0.0")
        let expectedURL = URL(string: "https://apps.apple.com/app/id123456789")!
        let info = AppUpdateInfo(
            latestVersion: "2.0.0",
            appStoreUrl: expectedURL.absoluteString
        )
        service.evaluateUpdate(with: info)

        var openedURL: URL?
        service.urlOpener = { url in
            openedURL = url
        }

        service.openAppStore()
        XCTAssertEqual(openedURL, expectedURL)
    }
}
