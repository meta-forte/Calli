import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var updateService: AppUpdateService
    @State private var showingLegal: Bool = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)

                        VStack(spacing: 4) {
                            Text("HanziSlate")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(white: 0.12))

                            Text("Version \(appVersion) (\(appBuild))")
                                .font(.system(size: 14))
                                .foregroundColor(Color(white: 0.45))

                            Text("Developed by Ibhatech")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(white: 0.35))
                        }
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("About HanziSlate")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(white: 0.25))

                        Text("HanziSlate is a dedicated Chinese character handwriting and listening study aid designed for learners preparing for the HSK 3.0 syllabus (Levels 1 to 9). Practice stroke tracing, directional guidance, pinyin pronunciation, and tones in a focused, offline-ready environment.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.20))
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.96))
                    .cornerRadius(12)

                    VStack(spacing: 12) {
                        Button(action: {
                            showingLegal = true
                        }) {
                            HStack {
                                Label("Legal & Attributions", systemImage: "doc.text")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                            }
                            .foregroundColor(Color(white: 0.15))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.96))
                            .cornerRadius(12)
                        }

                        Button(action: {
                            dismiss()
                            updateService.showUpdateSheet = true
                            Task {
                                await updateService.checkForUpdates()
                            }
                        }) {
                            HStack {
                                Label(
                                    updateService.hasUnreadUpdate ? "Update Available" : "Check for Updates",
                                    systemImage: updateService.hasUnreadUpdate ? "bell.badge.fill" : "bell"
                                )
                                .font(.system(size: 15, weight: .medium))
                                Spacer()
                                if updateService.hasUnreadUpdate {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                            }
                            .foregroundColor(Color(white: 0.15))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.96))
                            .cornerRadius(12)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.70))
                    }
                    .accessibilityLabel("Close")
                }
            }
            .sheet(isPresented: $showingLegal) {
                LegalView()
            }
        }
    }
}
