package com.ibhatech.hanzislate.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

private const val trademarkDisclaimerText =
    "HSK is a registered trademark of Chinese Testing International (CTI). This application is an independent study tool and is not affiliated with or endorsed by CTI or CLEC."

private const val makeMeAHanziText =
    "Chinese character stroke graphics and vector data are derived from the MakeMeAHanzi project (by skishore) and Arphic PL Fonts, released under the Arphic Public License (APL)."

private const val dictionaryText =
    "Dictionary data is derived from the Unihan Database and CJKlib under the LGPL-3.0 license."

private const val hskStandardText =
    "Character lists and standard levels are aligned with the official Chinese Proficiency Grading Standards for International Chinese Language Education (HSK 3.0)."

private val arphicLicenseText = """
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
""".trimIndent()

@Composable
fun LegalSheet(onDismiss: () -> Unit) {
    val uriHandler = LocalUriHandler.current
    var isShowingLicenseText by remember { mutableStateOf(false) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 10.dp)
            ) {
                Text(
                    text = "Legal & Attributions",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.PrimaryText,
                    modifier = Modifier.align(Alignment.Center)
                )
                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier.align(Alignment.CenterEnd)
                ) {
                    Icon(
                        imageVector = Icons.Default.Cancel,
                        contentDescription = "Close",
                        tint = Color(0.70f, 0.70f, 0.70f, 1f)
                    )
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                LegalSection(title = "Legal & Disclaimers", icon = Icons.Default.Shield) {
                    Text(
                        text = trademarkDisclaimerText,
                        fontSize = 14.sp,
                        color = Color(0.20f, 0.20f, 0.20f, 1f),
                        lineHeight = 19.sp
                    )
                }

                LegalSection(title = "Open-Source Attributions", icon = Icons.Default.Inventory2) {
                    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        AttributionItem(
                            title = "MakeMeAHanzi & Arphic PL Fonts",
                            body = makeMeAHanziText,
                            linkUrl = "https://github.com/skishore/makemeahanzi",
                            linkTitle = "GitHub: skishore/makemeahanzi",
                            onOpenUrl = { uriHandler.openUri(it) }
                        )

                        HorizontalDivider(color = AppColors.BorderGray)

                        AttributionItem(
                            title = "Unihan Database & CJKlib",
                            body = dictionaryText,
                            linkUrl = "https://www.gnu.org/licenses/lgpl-3.0.html",
                            linkTitle = "LGPL-3.0 License",
                            onOpenUrl = { uriHandler.openUri(it) }
                        )

                        HorizontalDivider(color = AppColors.BorderGray)

                        AttributionItem(
                            title = "HSK 3.0 Standard Curriculum",
                            body = hskStandardText,
                            linkUrl = null,
                            linkTitle = null,
                            onOpenUrl = {}
                        )
                    }
                }

                LegalSection(title = "Arphic Public License (APL)", icon = Icons.Default.Description) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { isShowingLicenseText = !isShowingLicenseText },
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = if (isShowingLicenseText) "Hide Full License Text" else "View Full License Text (1999)",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium,
                                color = AppColors.AccentBlue,
                                modifier = Modifier.weight(1f)
                            )
                            Icon(
                                imageVector = if (isShowingLicenseText) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                contentDescription = null,
                                tint = AppColors.AccentBlue
                            )
                        }

                        if (isShowingLicenseText) {
                            Text(
                                text = arphicLicenseText,
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = Color(0.30f, 0.30f, 0.30f, 1f),
                                lineHeight = 16.sp
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun LegalSection(
    title: String,
    icon: ImageVector,
    content: @Composable () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = AppColors.TertiaryText,
                modifier = Modifier.size(16.dp)
            )
            Text(
                text = title,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color(0.18f, 0.18f, 0.18f, 1f)
            )
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(AppColors.CardBackground)
                .padding(16.dp)
        ) {
            content()
        }
    }
}

@Composable
private fun AttributionItem(
    title: String,
    body: String,
    linkUrl: String?,
    linkTitle: String?,
    onOpenUrl: (String) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = title,
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color(0.15f, 0.15f, 0.15f, 1f)
        )
        Text(
            text = body,
            fontSize = 13.sp,
            color = Color(0.30f, 0.30f, 0.30f, 1f),
            lineHeight = 18.sp
        )
        if (!linkUrl.isNullOrEmpty() && !linkTitle.isNullOrEmpty()) {
            Row(
                modifier = Modifier
                    .clickable { onOpenUrl(linkUrl) }
                    .padding(top = 2.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = linkTitle,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = AppColors.AccentBlue
                )
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                    contentDescription = null,
                    tint = AppColors.AccentBlue,
                    modifier = Modifier.size(12.dp)
                )
            }
        }
    }
}
