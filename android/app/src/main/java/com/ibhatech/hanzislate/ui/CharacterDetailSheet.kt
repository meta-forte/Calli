package com.ibhatech.hanzislate.ui

import android.view.HapticFeedbackConstants
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.FormatSize
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.ibhatech.hanzislate.models.CanvasSize
import com.ibhatech.hanzislate.models.CharacterItem
import com.ibhatech.hanzislate.models.CharacterStrokeInfo
import com.ibhatech.hanzislate.models.GuideStrokeMode
import com.ibhatech.hanzislate.models.PreferenceStore
import com.ibhatech.hanzislate.models.Vec2
import com.ibhatech.hanzislate.services.AudioPlayerService
import com.ibhatech.hanzislate.services.PracticeStorageService
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

object CharacterDetailConfig {
    const val tracingFontSizeStorageKey = "kTracingCharacterFontSize"
    const val selectedGuideModeKey = "selectedGuideMode"
    const val defaultTracingFontSize: Double = 300.0
    const val minTracingFontSize: Double = 160.0
    const val maxTracingFontSize: Double = 520.0

    fun clampFontSize(value: Double): Double {
        return value.coerceIn(minTracingFontSize, maxTracingFontSize)
    }
}

@Composable
fun CharacterDetailSheet(
    character: CharacterItem,
    strokeInfo: CharacterStrokeInfo?,
    prefs: PreferenceStore,
    audioService: AudioPlayerService,
    practiceStorage: PracticeStorageService,
    onPrevious: (() -> Unit)?,
    onNext: (() -> Unit)?,
    onDismiss: () -> Unit
) {
    val view = LocalView.current
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()
    val isPlayingAudio by audioService.isPlayingFlow.collectAsState()

    var currentStrokeIndex by remember(character.id) { mutableIntStateOf(0) }
    var completedUserStrokes by remember(character.id) { mutableStateOf<List<List<Vec2>>>(emptyList()) }
    var isCompleted by remember(character.id) { mutableStateOf(false) }
    var todayPracticeCount by remember(character.id) {
        mutableIntStateOf(practiceStorage.getPracticeCount(character.hanzi))
    }
    var targetCanvasAlpha by remember(character.id) { mutableFloatStateOf(1f) }
    val animatedCanvasAlpha by animateFloatAsState(
        targetValue = targetCanvasAlpha,
        animationSpec = tween(durationMillis = 250),
        label = "canvasAlpha"
    )

    var selectedGuideMode by remember {
        mutableStateOf(
            GuideStrokeMode.fromRawValue(
                prefs.getString(CharacterDetailConfig.selectedGuideModeKey, GuideStrokeMode.SINGLE.rawValue)
            )
        )
    }
    var tracingFontSize by remember {
        mutableDoubleStateOf(
            CharacterDetailConfig.clampFontSize(
                prefs.getDouble(
                    CharacterDetailConfig.tracingFontSizeStorageKey,
                    CharacterDetailConfig.defaultTracingFontSize
                )
            )
        )
    }
    var isShowingFontSizeSlider by remember { mutableStateOf(false) }

    fun resetState() {
        currentStrokeIndex = 0
        completedUserStrokes = emptyList()
        isCompleted = false
    }

    fun performAnimatedErase() {
        scope.launch {
            targetCanvasAlpha = 0f
            delay(220)
            resetState()
            targetCanvasAlpha = 1f
        }
    }

    fun handleCompletion() {
        isCompleted = true
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        todayPracticeCount = practiceStorage.recordPractice(character.hanzi)
        audioService.playPronunciation(character)

        scope.launch {
            delay(1400)
            targetCanvasAlpha = 0f
            delay(500)
            resetState()
            targetCanvasAlpha = 1f
        }
    }

    LaunchedEffect(character.id) {
        resetState()
        todayPracticeCount = practiceStorage.getPracticeCount(character.hanzi)
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            dismissOnBackPress = true,
            dismissOnClickOutside = false
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(AppColors.AppBackground)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Cancel,
                        contentDescription = "Close",
                        tint = Color(0.45f, 0.45f, 0.45f, 1f),
                        modifier = Modifier.size(24.dp)
                    )
                }

                Text(
                    text = if (character.isHSK) character.levelTitle else "Other Character",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.PrimaryText,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f)
                )

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val sliderTint = if (isShowingFontSizeSlider) AppColors.AccentBlue else Color(0.30f, 0.30f, 0.30f, 1f)
                    val sliderBorder = if (isShowingFontSizeSlider) AppColors.AccentBlue else AppColors.BorderGray
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color.White)
                            .border(1.dp, sliderBorder, RoundedCornerShape(8.dp))
                            .clickable { isShowingFontSizeSlider = !isShowingFontSizeSlider }
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.FormatSize,
                            contentDescription = "Tracing font size options",
                            tint = sliderTint,
                            modifier = Modifier.size(15.dp)
                        )
                        Text(
                            text = "${tracingFontSize.toInt()} pt",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = sliderTint
                        )
                    }

                    IconButton(onClick = { audioService.playPronunciation(character) }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.VolumeUp,
                            contentDescription = "Play pronunciation",
                            tint = if (isPlayingAudio) AppColors.AccentBlue else AppColors.AccentBlue.copy(alpha = 0.85f),
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }
            }

            BoxWithConstraints(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp)
            ) {
                val marginDp = 32.dp
                val topBottomSpacingDp = if (isShowingFontSizeSlider) 300.dp else 240.dp
                val availWidth = (maxWidth - marginDp).value.toDouble()
                val availHeight = (maxHeight - topBottomSpacingDp).value.toDouble()
                val maxAllowedDimension = max(
                    CharacterDetailConfig.minTracingFontSize,
                    min(availWidth, availHeight)
                )
                val canvasDimension = min(
                    max(tracingFontSize, CharacterDetailConfig.minTracingFontSize),
                    maxAllowedDimension
                )

                LaunchedEffect(canvasDimension.roundToInt()) {
                    resetState()
                }

                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                        modifier = Modifier.padding(top = 4.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.Bottom,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = character.pinyin,
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold,
                                color = AppColors.PrimaryText
                            )
                            if (character.meaning.isNotEmpty()) {
                                Text(
                                    text = "•  ${character.meaning}",
                                    fontSize = 15.sp,
                                    color = AppColors.SecondaryText,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }

                        if (character.exampleChinese.isNotEmpty()) {
                            Text(
                                text = "${character.exampleChinese}  ${character.examplePinyin}",
                                fontSize = 13.sp,
                                color = AppColors.SecondaryText,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color.White)
                                .border(1.dp, AppColors.BorderGray, RoundedCornerShape(12.dp))
                                .padding(horizontal = 10.dp, vertical = 3.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Repeat,
                                contentDescription = null,
                                tint = AppColors.AccentBlue,
                                modifier = Modifier.size(13.dp)
                            )
                            Text(
                                text = "Repetitions today: $todayPracticeCount",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = AppColors.SecondaryText
                            )
                        }
                    }

                    AnimatedVisibility(
                        visible = isShowingFontSizeSlider,
                        enter = fadeIn() + slideInVertically(),
                        exit = fadeOut() + slideOutVertically()
                    ) {
                        val sliderUpperBound = max(
                            CharacterDetailConfig.minTracingFontSize + 40.0,
                            maxAllowedDimension
                        ).toFloat()
                        val stepsCount = (((sliderUpperBound - CharacterDetailConfig.minTracingFontSize.toFloat()) / 5f).toInt() - 1)
                            .coerceAtLeast(0)

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color.White)
                                .border(1.dp, AppColors.BorderGray, RoundedCornerShape(12.dp))
                                .padding(horizontal = 14.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                text = "文",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium,
                                color = AppColors.SecondaryText
                            )

                            Slider(
                                value = tracingFontSize.toFloat().coerceIn(
                                    CharacterDetailConfig.minTracingFontSize.toFloat(),
                                    sliderUpperBound
                                ),
                                onValueChange = { newVal ->
                                    val stepped = (newVal / 5f).roundToInt() * 5.0
                                    val clamped = CharacterDetailConfig.clampFontSize(stepped)
                                    tracingFontSize = clamped
                                    prefs.putDouble(CharacterDetailConfig.tracingFontSizeStorageKey, clamped)
                                },
                                valueRange = CharacterDetailConfig.minTracingFontSize.toFloat()..sliderUpperBound,
                                steps = stepsCount,
                                colors = SliderDefaults.colors(
                                    thumbColor = AppColors.AccentBlue,
                                    activeTrackColor = AppColors.AccentBlue
                                ),
                                modifier = Modifier.weight(1f)
                            )

                            Text(
                                text = "文",
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold,
                                color = AppColors.SecondaryText
                            )

                            Text(
                                text = "${canvasDimension.toInt()} pt",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold,
                                fontFamily = FontFamily.Monospace,
                                color = Color(0.25f, 0.25f, 0.25f, 1f),
                                modifier = Modifier.widthIn(min = 50.dp),
                                textAlign = TextAlign.End
                            )
                        }
                    }

                    val totalStrokes = strokeInfo?.strokes?.size ?: 0
                    if (strokeInfo != null && strokeInfo.strokes.isNotEmpty()) {
                        StrokeCanvasView(
                            character = character.hanzi,
                            strokeInfo = strokeInfo,
                            canvasSizeDp = canvasDimension.dp,
                            currentStrokeIndex = currentStrokeIndex,
                            onCurrentStrokeIndexChange = { currentStrokeIndex = it },
                            completedUserStrokes = completedUserStrokes,
                            onCompletedUserStrokesChange = { completedUserStrokes = it },
                            isCompleted = isCompleted,
                            mode = selectedGuideMode,
                            onStrokeCompleted = {},
                            onAllStrokesCompleted = { handleCompletion() },
                            modifier = Modifier.alpha(animatedCanvasAlpha)
                        )

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            if (isCompleted) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.CheckCircle,
                                        contentDescription = null,
                                        tint = AppColors.AccentGreen,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Text(
                                        text = "Completed! Resetting...",
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = AppColors.AccentGreen
                                    )
                                }
                            } else {
                                Text(
                                    text = "Stroke ${min(currentStrokeIndex + 1, totalStrokes)} of $totalStrokes",
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = AppColors.SecondaryText
                                )
                            }

                            Spacer(modifier = Modifier.weight(1f))

                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color.White)
                                    .border(1.dp, AppColors.AccentBlue.copy(alpha = 0.2f), RoundedCornerShape(8.dp))
                                    .clickable {
                                        if (!isCompleted && currentStrokeIndex < totalStrokes) {
                                            val pxSize = with(density) { canvasDimension.dp.toPx().toDouble() }
                                            val median = strokeInfo.medianPoints(
                                                currentStrokeIndex,
                                                CanvasSize(pxSize, pxSize)
                                            )
                                            val updated = completedUserStrokes + listOf(median)
                                            completedUserStrokes = updated
                                            if (updated.size >= totalStrokes) {
                                                handleCompletion()
                                            } else {
                                                currentStrokeIndex += 1
                                            }
                                        }
                                    }
                                    .padding(horizontal = 10.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = if (isCompleted) "Repeating..." else "Trace Next",
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = AppColors.AccentBlue
                                )
                            }
                        }
                    } else {
                        Box(
                            modifier = Modifier.size(canvasDimension.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                Text(
                                    text = character.hanzi,
                                    fontSize = (canvasDimension * 0.58).sp,
                                    color = AppColors.TertiaryText
                                )
                                Text(
                                    text = "Stroke data unavailable",
                                    fontSize = 15.sp,
                                    color = AppColors.SecondaryText
                                )
                            }
                        }
                    }

                    SegmentedPicker(
                        options = GuideStrokeMode.entries,
                        selected = selectedGuideMode,
                        label = { it.rawValue },
                        onSelect = { mode ->
                            selectedGuideMode = mode
                            prefs.putString(CharacterDetailConfig.selectedGuideModeKey, mode.rawValue)
                        },
                        modifier = Modifier.width(280.dp)
                    )

                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(16.dp))
                            .background(Color.White)
                            .border(1.dp, AppColors.BorderGray, RoundedCornerShape(16.dp))
                            .clickable { performAnimatedErase() }
                            .padding(horizontal = 14.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = null,
                            tint = Color(0.15f, 0.15f, 0.15f, 1f),
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = "Erase and Repeat",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color(0.15f, 0.15f, 0.15f, 1f)
                        )
                    }

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(24.dp),
                        modifier = Modifier.padding(vertical = 2.dp)
                    ) {
                        CircleControlIcon(
                            icon = Icons.Default.ChevronLeft,
                            contentDescription = "Previous Character",
                            enabled = onPrevious != null,
                            onClick = { onPrevious?.invoke() }
                        )

                        CircleControlIcon(
                            icon = Icons.Default.Refresh,
                            contentDescription = "Reset Character",
                            enabled = true,
                            onClick = { performAnimatedErase() }
                        )

                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(CircleShape)
                                .background(AppColors.AccentBlue)
                                .clickable { audioService.playPronunciation(character) },
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.VolumeUp,
                                contentDescription = "Speak Character",
                                tint = Color.White,
                                modifier = Modifier.size(20.dp)
                            )
                        }

                        CircleControlIcon(
                            icon = Icons.Default.ChevronRight,
                            contentDescription = "Next Character",
                            enabled = onNext != null,
                            onClick = { onNext?.invoke() }
                        )
                    }

                    Spacer(modifier = Modifier.height(6.dp))
                }
            }
        }
    }
}

@Composable
private fun CircleControlIcon(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    contentDescription: String,
    enabled: Boolean,
    onClick: () -> Unit
) {
    val tint = if (enabled) Color(0.20f, 0.20f, 0.20f, 1f) else Color(0.72f, 0.72f, 0.72f, 1f)
    Box(
        modifier = Modifier
            .size(32.dp)
            .clip(CircleShape)
            .border(1.5.dp, tint, CircleShape)
            .then(if (enabled) Modifier.clickable(onClick = onClick) else Modifier),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = tint,
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
fun <T> SegmentedPicker(
    options: List<T>,
    selected: T,
    label: (T) -> String,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(Color(0.89f, 0.89f, 0.91f, 1f))
            .padding(2.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        for (option in options) {
            val isSelected = option == selected
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(6.dp))
                    .background(if (isSelected) Color.White else Color.Transparent)
                    .clickable { onSelect(option) }
                    .padding(vertical = 6.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = label(option),
                    fontSize = 13.sp,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                    color = AppColors.PrimaryText
                )
            }
        }
    }
}
