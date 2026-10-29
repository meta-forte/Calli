import SwiftUI

struct ForcedUpdateView: View {
    @ObservedObject var updateService: AppUpdateService

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.orange)

                    Text("Update Required")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(white: 0.12))

                    let latest = updateService.updateInfo?.latestVersion ?? "latest"
                    Text("You are using an unsupported version of HanziSlate (v\(updateService.currentVersionString)). Please update to v\(latest) to continue using the app.")
                        .font(.system(size: 16))
                        .foregroundColor(Color(white: 0.40))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let notes = updateService.updateInfo?.releaseNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's New")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(white: 0.35))

                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.18))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(white: 0.88), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                Button(action: {
                    updateService.openAppStore()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.app.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Update on App Store")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(14)
                    .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
