import CryptoKit
import Foundation
import UIKit

struct PropertyConfig {
    static func loadProperties(named fileName: String, bundle: Bundle = .main) -> [String: String] {
        guard let url = bundle.url(forResource: fileName, withExtension: "properties"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        return parse(content: content)
    }

    static func parse(content: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("!") {
                continue
            }
            if let separatorIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
                result[key] = value
            }
        }
        return result
    }
}

struct AppVersion: Comparable, Equatable {
    let components: [Int]

    init(_ versionString: String) {
        let clean = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        self.components = Array(
            clean.split(separator: ".")
                .compactMap { Int($0) }
                .filter { $0 >= 0 }
                .prefix(8)
        )
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for i in 0..<maxCount {
            let left = i < lhs.components.count ? lhs.components[i] : 0
            let right = i < rhs.components.count ? rhs.components[i] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }
}

struct SignedVersionResponse: Codable, Equatable {
    let payload: AppUpdateInfo
    let signature: String
}

struct AppUpdateInfo: Codable, Equatable {
    let latestVersion: String
    let minSupportedVersion: String?
    let releaseNotes: String?
    let appStoreUrl: String?
    let forceUpdate: Bool?

    enum CodingKeys: String, CodingKey {
        case latestVersion = "latest_version"
        case latestVersionAlt = "latestVersion"
        case minSupportedVersion = "min_supported_version"
        case minSupportedVersionAlt = "minSupportedVersion"
        case minimumVersion = "minimum_version"
        case releaseNotes = "release_notes"
        case releaseNotesAlt = "releaseNotes"
        case message
        case appStoreUrl = "app_store_url"
        case appStoreUrlAlt = "appStoreUrl"
        case storeUrl = "store_url"
        case forceUpdate = "force_update"
        case forceUpdateAlt = "forceUpdate"
    }

    init(
        latestVersion: String,
        minSupportedVersion: String? = nil,
        releaseNotes: String? = nil,
        appStoreUrl: String? = nil,
        forceUpdate: Bool? = nil
    ) {
        self.latestVersion = latestVersion
        self.minSupportedVersion = minSupportedVersion
        self.releaseNotes = releaseNotes
        self.appStoreUrl = appStoreUrl
        self.forceUpdate = forceUpdate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let latest = (try? container.decode(String.self, forKey: .latestVersion))
            ?? (try? container.decode(String.self, forKey: .latestVersionAlt))
            ?? "1.0.0"
        self.latestVersion = latest

        self.minSupportedVersion = (try? container.decode(String.self, forKey: .minSupportedVersion))
            ?? (try? container.decode(String.self, forKey: .minSupportedVersionAlt))
            ?? (try? container.decode(String.self, forKey: .minimumVersion))

        self.releaseNotes = (try? container.decode(String.self, forKey: .releaseNotes))
            ?? (try? container.decode(String.self, forKey: .releaseNotesAlt))
            ?? (try? container.decode(String.self, forKey: .message))

        self.appStoreUrl = (try? container.decode(String.self, forKey: .appStoreUrl))
            ?? (try? container.decode(String.self, forKey: .appStoreUrlAlt))
            ?? (try? container.decode(String.self, forKey: .storeUrl))

        self.forceUpdate = (try? container.decode(Bool.self, forKey: .forceUpdate))
            ?? (try? container.decode(Bool.self, forKey: .forceUpdateAlt))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latestVersion, forKey: .latestVersion)
        try container.encodeIfPresent(minSupportedVersion, forKey: .minSupportedVersion)
        try container.encodeIfPresent(releaseNotes, forKey: .releaseNotes)
        try container.encodeIfPresent(appStoreUrl, forKey: .appStoreUrl)
        try container.encodeIfPresent(forceUpdate, forKey: .forceUpdate)
    }
}

@MainActor
final class AppUpdateService: ObservableObject {
    static let shared = AppUpdateService()

    @Published var updateInfo: AppUpdateInfo?
    @Published var isChecking: Bool = false
    @Published var isForcedUpdate: Bool = false
    @Published var isOptionalUpdate: Bool = false
    @Published var showUpdateSheet: Bool = false
    @Published var hasUnreadUpdate: Bool = false
    @Published var errorMessage: String?

    let currentVersionString: String
    var urlOpener: ((URL) -> Void)?

    private let urlSession: URLSession

    init(
        currentVersion: String? = nil,
        urlSession: URLSession = .shared
    ) {
        self.currentVersionString = currentVersion ?? (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
        self.urlSession = urlSession
    }

    var configuredUpdateURL: URL? {
        let appConfig = PropertyConfig.loadProperties(named: "AppConfig")
        let metadata = PropertyConfig.loadProperties(named: "AppStoreMetadata")
        let rawURL = appConfig["update_check_url"]
            ?? appConfig["app.update_check_url"]
            ?? metadata["app.update_check_url"]
            ?? metadata["update_check_url"]
            ?? "http://localhost:8000"

        guard let initialURL = URL(string: rawURL) else { return nil }
        if initialURL.path.isEmpty || initialURL.path == "/" {
            return initialURL.appendingPathComponent("version.json")
        }
        return initialURL
    }

    var configuredPublicKey: String? {
        let appConfig = PropertyConfig.loadProperties(named: "AppConfig")
        let metadata = PropertyConfig.loadProperties(named: "AppStoreMetadata")
        let key = appConfig["update_public_key"]
            ?? appConfig["app.update_public_key"]
            ?? metadata["app.update_public_key"]
            ?? metadata["update_public_key"]
        guard let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    nonisolated static func isValidAppStoreURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "itms-apps",
              let host = url.host?.lowercased(),
              host == "apps.apple.com",
              url.user == nil,
              url.password == nil else {
            return false
        }
        return true
    }

    nonisolated static func verifySignedPayload(data: Data, publicKeyBase64: String) throws -> AppUpdateInfo {
        guard let pubKeyData = Data(base64Encoded: publicKeyBase64.trimmingCharacters(in: .whitespacesAndNewlines)),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: pubKeyData) else {
            throw URLError(.cannotDecodeContentData)
        }

        if let rootObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let payloadDict = rootObject["payload"] as? [String: Any],
           let signatureString = rootObject["signature"] as? String,
           let signatureData = Data(base64Encoded: signatureString),
           let canonicalData = try? JSONSerialization.data(
               withJSONObject: payloadDict,
               options: [.sortedKeys, .withoutEscapingSlashes]
           ) {
            if publicKey.isValidSignature(signatureData, for: canonicalData) {
                return try JSONDecoder().decode(AppUpdateInfo.self, from: canonicalData)
            }
        }

        let signedResponse = try JSONDecoder().decode(SignedVersionResponse.self, from: data)
        guard let signatureData = Data(base64Encoded: signedResponse.signature) else {
            throw URLError(.cannotDecodeContentData)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let payloadJson = try encoder.encode(signedResponse.payload)
        guard publicKey.isValidSignature(signatureData, for: payloadJson) else {
            throw URLError(.secureConnectionFailed)
        }
        return signedResponse.payload
    }

    var appStoreURL: URL? {
        if let customUrl = updateInfo?.appStoreUrl,
           let url = URL(string: customUrl),
           Self.isValidAppStoreURL(url) {
            return url
        }
        let appConfig = PropertyConfig.loadProperties(named: "AppConfig")
        let metadata = PropertyConfig.loadProperties(named: "AppStoreMetadata")
        if let raw = appConfig["app_store_url"] ?? metadata["app.store_url"],
           let url = URL(string: raw),
           Self.isValidAppStoreURL(url) {
            return url
        }
        return URL(string: "https://apps.apple.com")
    }

    func checkForUpdates(from customURL: URL? = nil) async {
        guard let url = customURL ?? configuredUpdateURL else { return }
        isChecking = true
        errorMessage = nil

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 5.0

            let (data, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                errorMessage = "Server returned status \(httpResponse.statusCode)"
                isChecking = false
                return
            }

            if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               root["payload"] != nil || root["signature"] != nil {
                guard let pubKey = configuredPublicKey else {
                    throw URLError(.secureConnectionFailed)
                }
                let info = try Self.verifySignedPayload(data: data, publicKeyBase64: pubKey)
                evaluateUpdate(with: info)
            } else {
                let info = try JSONDecoder().decode(AppUpdateInfo.self, from: data)
                evaluateUpdate(with: info)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isChecking = false
    }

    func evaluateUpdate(with info: AppUpdateInfo) {
        self.updateInfo = info
        let current = AppVersion(currentVersionString)
        let latest = AppVersion(info.latestVersion)

        if let minVersionString = info.minSupportedVersion {
            let minVersion = AppVersion(minVersionString)
            if current < minVersion {
                self.isForcedUpdate = true
                self.isOptionalUpdate = false
                self.hasUnreadUpdate = true
                return
            }
        }

        if info.forceUpdate == true && current < latest {
            self.isForcedUpdate = true
            self.isOptionalUpdate = false
            self.hasUnreadUpdate = true
            return
        }

        if current < latest {
            self.isForcedUpdate = false
            self.isOptionalUpdate = true
            self.hasUnreadUpdate = true
        } else {
            self.isForcedUpdate = false
            self.isOptionalUpdate = false
            self.hasUnreadUpdate = false
        }
    }

    func dismissOptionalNotice() {
        showUpdateSheet = false
        hasUnreadUpdate = false
    }

    func openAppStore() {
        guard let url = appStoreURL else { return }
        if let opener = urlOpener {
            opener(url)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
