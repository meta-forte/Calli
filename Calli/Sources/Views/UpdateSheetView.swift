import SwiftUI

struct UpdateSheetView: View {
    @ObservedObject var updateService: AppUpdateService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if updateService.isChecking {
                    checkingView
                } else if updateService.isOptionalUpdate || updateService.isForcedUpdate {
                    updateAvailableView
                } else if updateService.updateInfo != nil {
                    upToDateView
                } else {
                    connectionFailedView
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        updateService.dismissOptionalNotice()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.70))
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var checkingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Checking for updates...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(white: 0.40))
            Spacer()
        }
    }

    private var updateAvailableView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)

                Text("Update Available")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(white: 0.12))

                if let latest = updateService.updateInfo?.latestVersion {
                    Text("Version \(latest) is now available (Current: \(updateService.currentVersionString))")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.42))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 8)

            if let notes = updateService.updateInfo?.releaseNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's New")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(white: 0.35))

                    Text(notes)
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.18))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color(white: 0.96))
                        .cornerRadius(10)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    updateService.openAppStore()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.app.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Update on App Store")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Button(action: {
                    updateService.dismissOptionalNotice()
                    dismiss()
                }) {
                    Text("Later")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.42))
                        .padding(.vertical, 8)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private var upToDateView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)

                Text("You're Up to Date")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(white: 0.12))

                Text("HanziSlate \(updateService.currentVersionString) is currently the latest version.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.42))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: {
                updateService.dismissOptionalNotice()
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.bottom, 8)
        }
    }

    private var connectionFailedView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.94))
                        .frame(width: 80, height: 80)
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(Color(white: 0.35))
                }

                Text("Unable to Check for Updates")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(white: 0.12))

                Text("Could not connect to the update server. Please check your internet connection and try again later.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.42))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text("Current Version: \(updateService.currentVersionString)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(white: 0.45))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.94))
                    .cornerRadius(8)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await updateService.checkForUpdates()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Try Again")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Button(action: {
                    updateService.dismissOptionalNotice()
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.42))
                        .padding(.vertical, 8)
                }
            }
            .padding(.bottom, 8)
        }
    }
}
