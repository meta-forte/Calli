import SwiftUI

@main
struct CalliApp: App {
    @StateObject private var updateService = AppUpdateService.shared

    init() {
        UserDefaults.standard.register(defaults: [
            "kTracingCharacterFontSize": 300.0
        ])
    }

    var body: some Scene {
        WindowGroup {
            CharacterGridView()
                .environmentObject(updateService)
                .task {
                    await updateService.checkForUpdates()
                }
                .preferredColorScheme(.light)
        }
    }
}
