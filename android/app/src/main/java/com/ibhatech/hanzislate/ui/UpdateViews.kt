package com.ibhatech.hanzislate.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ibhatech.hanzislate.R
import com.ibhatech.hanzislate.services.AppUpdateService
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UpdateSheetView(
    updateService: AppUpdateService,
    onDismiss: () -> Unit
) {
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val isChecking by updateService.isCheckingFlow.collectAsState()
    val isOptionalUpdate by updateService.isOptionalUpdateFlow.collectAsState()
    val isForcedUpdate by updateService.isForcedUpdateFlow.collectAsState()
    val updateInfo by updateService.updateInfoFlow.collectAsState()

    ModalBottomSheet(
        onDismissRequest = {
            updateService.dismissOptionalNotice()
            onDismiss()
        },
        sheetState = sheetState,
        containerColor = Color.White
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Box(modifier = Modifier.fillMaxWidth()) {
                IconButton(
                    onClick = {
                        updateService.dismissOptionalNotice()
                        onDismiss()
                    },
                    modifier = Modifier.align(Alignment.CenterEnd)
                ) {
                    Icon(
                        imageVector = Icons.Default.Cancel,
                        contentDescription = "Close",
                        tint = Color(0.70f, 0.70f, 0.70f, 1f)
                    )
                }
            }

            when {
                isChecking -> {
                    Column(
                        modifier = Modifier.padding(vertical = 48.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        CircularProgressIndicator(color = AppColors.AccentBlue)
                        Text(
                            text = "Checking for updates...",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color(0.40f, 0.40f, 0.40f, 1f)
                        )
                    }
                }
                isOptionalUpdate || isForcedUpdate -> {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Image(
                            painter = painterResource(id = R.drawable.app_logo),
                            contentDescription = "App Logo",
                            modifier = Modifier
                                .size(64.dp)
                                .shadow(6.dp, RoundedCornerShape(14.dp))
                                .clip(RoundedCornerShape(14.dp))
                        )
                        Text(
                            text = "Update Available",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.PrimaryText
                        )
                        updateInfo?.latestVersion?.let { latest ->
                            Text(
                                text = "Version $latest is now available (Current: ${updateService.currentVersionString})",
                                fontSize = 14.sp,
                                color = AppColors.SecondaryText,
                                textAlign = TextAlign.Center
                            )
                        }
                    }

                    val notes = updateInfo?.releaseNotes
                    if (!notes.isNullOrEmpty()) {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = "What's New",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = AppColors.TertiaryText
                            )
                            Text(
                                text = notes,
                                fontSize = 15.sp,
                                color = Color(0.18f, 0.18f, 0.18f, 1f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(AppColors.CardBackground)
                                    .padding(14.dp)
                            )
                        }
                    }

                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(AppColors.AccentBlue)
                                .clickable { updateService.openAppStore() }
                                .padding(vertical = 14.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Download,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(18.dp)
                            )
                            Text(
                                text = "  Update App",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White
                            )
                        }

                        Text(
                            text = "Later",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium,
                            color = AppColors.SecondaryText,
                            modifier = Modifier
                                .clickable {
                                    updateService.dismissOptionalNotice()
                                    onDismiss()
                                }
                                .padding(vertical = 8.dp)
                        )
                    }
                }
                updateInfo != null -> {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(14.dp),
                        modifier = Modifier.padding(vertical = 24.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = AppColors.AccentGreen,
                            modifier = Modifier.size(56.dp)
                        )
                        Text(
                            text = "You're Up to Date",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.PrimaryText
                        )
                        Text(
                            text = "HanziSlate ${updateService.currentVersionString} is currently the latest version.",
                            fontSize = 14.sp,
                            color = AppColors.SecondaryText,
                            textAlign = TextAlign.Center
                        )
                    }

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(AppColors.AccentBlue)
                            .clickable {
                                updateService.dismissOptionalNotice()
                                onDismiss()
                            }
                            .padding(vertical = 14.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Done",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White
                        )
                    }
                }
                else -> {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(80.dp)
                                .clip(CircleShape)
                                .background(Color(0.94f, 0.94f, 0.94f, 1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.WifiOff,
                                contentDescription = null,
                                tint = AppColors.TertiaryText,
                                modifier = Modifier.size(34.dp)
                            )
                        }

                        Text(
                            text = "Unable to Check for Updates",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.PrimaryText
                        )

                        Text(
                            text = "Could not connect to the update server. Please check your internet connection and try again later.",
                            fontSize = 14.sp,
                            color = AppColors.SecondaryText,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )

                        Text(
                            text = "Current Version: ${updateService.currentVersionString}",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color(0.45f, 0.45f, 0.45f, 1f),
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0.94f, 0.94f, 0.94f, 1f))
                                .padding(horizontal = 12.dp, vertical = 6.dp)
                        )
                    }

                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(AppColors.AccentBlue)
                                .clickable {
                                    scope.launch {
                                        updateService.checkForUpdates()
                                    }
                                }
                                .padding(vertical = 14.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Refresh,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = "  Try Again",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White
                            )
                        }

                        Text(
                            text = "Done",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium,
                            color = AppColors.SecondaryText,
                            modifier = Modifier
                                .clickable {
                                    updateService.dismissOptionalNotice()
                                    onDismiss()
                                }
                                .padding(vertical = 8.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ForcedUpdateView(updateService: AppUpdateService) {
    val updateInfo by updateService.updateInfoFlow.collectAsState()
    val latest = updateInfo?.latestVersion ?: "latest"
    val notes = updateInfo?.releaseNotes

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.AppBackground)
            .padding(horizontal = 24.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Spacer(modifier = Modifier.weight(1f))

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = null,
                tint = AppColors.AccentOrange,
                modifier = Modifier.size(64.dp)
            )
            Text(
                text = "Update Required",
                fontSize = 26.sp,
                fontWeight = FontWeight.Bold,
                color = AppColors.PrimaryText
            )
            Text(
                text = "You are using an unsupported version of HanziSlate (v${updateService.currentVersionString}). Please update to v$latest to continue using the app.",
                fontSize = 16.sp,
                color = Color(0.40f, 0.40f, 0.40f, 1f),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 8.dp)
            )
        }

        if (!notes.isNullOrEmpty()) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "What's New",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.TertiaryText
                )
                Text(
                    text = notes,
                    fontSize = 14.sp,
                    color = Color(0.18f, 0.18f, 0.18f, 1f),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color.White)
                        .border(1.dp, Color(0.88f, 0.88f, 0.88f, 1f), RoundedCornerShape(10.dp))
                        .padding(14.dp)
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(AppColors.AccentBlue)
                .clickable { updateService.openAppStore() }
                .padding(vertical = 16.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Download,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = "  Update App",
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White
            )
        }
    }
}
