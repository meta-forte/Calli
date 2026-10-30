import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingLicenseText: Bool = false

    private let trademarkDisclaimerText = "HSK is a registered trademark of Chinese Testing International (CTI). This application is an independent study tool and is not affiliated with or endorsed by CTI or CLEC."

    private let makeMeAHanziText = "Chinese character stroke graphics and vector data are derived from the MakeMeAHanzi project (by skishore) and Arphic PL Fonts, released under the Arphic Public License (APL)."

    private let dictionaryText = "Dictionary data is derived from the Unihan Database and CJKlib under the LGPL-3.0 license."

    private let hskStandardText = "Character lists and standard levels are aligned with the official Chinese Proficiency Grading Standards for International Chinese Language Education (HSK 3.0)."

    private let arphicLicenseText = """
ARPHIC PUBLIC LICENSE

Copyright (C) 1999 Arphic Technology Co., Ltd.
11Fl. No.168, Yung Chi Rd., Taipei, 110 Taiwan
All rights reserved except as specified below.

Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is forbidden.

Preamble
The licenses for most software are designed to take away your freedom to share and change it. By contrast, the ARPHIC PUBLIC LICENSE specifically permits and encourages you to use this software, provided that you give the recipients all the rights that we gave you and make sure they can get the modifications of this software.

Legal Terms

0. Definitions:
Throughout this License, "Font" means the TrueType fonts "AR PL Mingti2L Big5", "AR PL KaitiM Big5" (BIG-5 character set) and "AR PL SungtiL GB", "AR PL KaitiM GB" (GB character set) which are originally distributed by Arphic, and the derivatives of those fonts created through any modification including modifying glyph, reordering glyph, converting format, changing font name, or adding/deleting some characters in/from glyph table.

"PL" means "Public License".
"Copyright Holder" means whoever is named in the copyright or copyrights for the Font.
"You" means the licensee, or person copying, redistributing or modifying the Font.
"Freely Available" means that you have the freedom to copy or modify the Font as well as redistribute copies of the Font under the same conditions you received, not price. If you wish, you can charge for this service.

1. Copying & Distribution
You may copy and distribute verbatim copies of this Font in any medium, without restriction, provided that you retain this license file (ARPHICPL.TXT) unaltered in all copies.

2. Modification
You may otherwise modify your copy of this Font in any way, including modifying glyph, reordering glyph, converting format, changing font name, or adding/deleting some characters in/from glyph table, and copy and distribute such modifications under the terms of Section 1 above, provided that the following conditions are met:
a) You must insert a prominent notice in each modified file stating how and when you changed that file.
b) You must make such modifications Freely Available as a whole to all third parties under the terms of this License.
c) If the modified fonts normally reads commands interactively when run, you must cause it to print or display an announcement including an appropriate copyright notice and a notice that there is no warranty.

3. Condition Subsequent
You may not copy, modify, sublicense, or distribute the Font except as expressly provided under this License.

4. Acceptance
By copying, modifying, sublicensing or distributing the Font, you indicate your acceptance of this License and all its terms and conditions.

5. Automatic Receipt
Each time you redistribute the Font, the recipient automatically receives a license from the original licensor to copy, distribute or modify the Font subject to these terms and conditions.

6. Contradiction
If conditions are imposed on you that contradict the conditions of this License, they do not excuse you from the conditions of this License.

7. NO WARRANTY
BECAUSE THE FONT IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE FONT, TO THE EXTENT PERMITTED BY APPLICABLE LAW.

8. DAMAGES WAIVER
IN NO EVENT WILL ANY COPYRIGHT HOLDERS BE LIABLE TO YOU FOR ANY DIRECT, INDIRECT, CONSEQUENTIAL, INCIDENTAL, SPECIAL OR EXEMPLARY DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE FONT.
"""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    legalSection(
                        title: "Legal & Disclaimers",
                        icon: "shield.fill"
                    ) {
                        Text(trademarkDisclaimerText)
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.20))
                            .lineSpacing(3)
                    }

                    legalSection(
                        title: "Open-Source Attributions",
                        icon: "shippingbox.fill"
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            attributionItem(
                                title: "MakeMeAHanzi & Arphic PL Fonts",
                                body: makeMeAHanziText,
                                linkUrl: "https://github.com/skishore/makemeahanzi",
                                linkTitle: "GitHub: skishore/makemeahanzi"
                            )

                            Divider()

                            attributionItem(
                                title: "Unihan Database & CJKlib",
                                body: dictionaryText,
                                linkUrl: "https://www.gnu.org/licenses/lgpl-3.0.html",
                                linkTitle: "LGPL-3.0 License"
                            )

                            Divider()

                            attributionItem(
                                title: "HSK 3.0 Standard Curriculum",
                                body: hskStandardText,
                                linkUrl: nil,
                                linkTitle: nil
                            )
                        }
                    }

                    legalSection(
                        title: "Arphic Public License (APL)",
                        icon: "doc.text.fill"
                    ) {
                        DisclosureGroup(
                            isExpanded: $isShowingLicenseText,
                            content: {
                                Text(arphicLicenseText)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color(white: 0.30))
                                    .padding(.top, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            },
                            label: {
                                Text(isShowingLicenseText ? "Hide Full License Text" : "View Full License Text (1999)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        )
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Legal & Attributions")
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
        }
    }

    private func legalSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(white: 0.35))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(white: 0.18))
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(white: 0.96))
            .cornerRadius(12)
        }
    }

    private func attributionItem(
        title: String,
        body: String,
        linkUrl: String?,
        linkTitle: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(white: 0.15))

            Text(body)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.30))
                .lineSpacing(2)

            if let urlString = linkUrl, let titleString = linkTitle, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text(titleString)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 2)
            }
        }
    }
}
