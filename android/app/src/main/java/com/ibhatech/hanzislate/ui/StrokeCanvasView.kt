package com.ibhatech.hanzislate.ui

import android.graphics.PathMeasure
import android.view.HapticFeedbackConstants
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.asComposePath
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Dp
import com.ibhatech.hanzislate.models.CanvasSize
import com.ibhatech.hanzislate.models.CharacterStrokeInfo
import com.ibhatech.hanzislate.models.GuideStrokeMode
import com.ibhatech.hanzislate.models.NotoGlyphProvider
import com.ibhatech.hanzislate.models.StrokeMatcher
import com.ibhatech.hanzislate.models.StrokePathParser
import com.ibhatech.hanzislate.models.StrokeSmoother
import com.ibhatech.hanzislate.models.Vec2
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.max

@Composable
fun StrokeCanvasView(
    character: String,
    strokeInfo: CharacterStrokeInfo,
    canvasSizeDp: Dp,
    currentStrokeIndex: Int,
    onCurrentStrokeIndexChange: (Int) -> Unit,
    completedUserStrokes: List<List<Vec2>>,
    onCompletedUserStrokesChange: (List<List<Vec2>>) -> Unit,
    isCompleted: Boolean,
    mode: GuideStrokeMode,
    onStrokeCompleted: (Int) -> Unit,
    onAllStrokesCompleted: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val view = LocalView.current
    val density = LocalDensity.current
    val canvasSizePx = with(density) { canvasSizeDp.toPx().toDouble() }
    val logicalSize = CanvasSize(canvasSizePx, canvasSizePx)
    val scaleFactor = canvasSizePx / 300.0
    val strokeWidthPx = max(6.0 * density.density, canvasSizePx * 0.032).toFloat()

    val scope = rememberCoroutineScope()
    val currentUserPoints = remember { mutableStateListOf<Vec2>() }
    var matchedProgress by remember { mutableIntStateOf(0) }
    var hasReachedTarget by remember { mutableStateOf(false) }
    val strokeProgresses = remember { mutableStateMapOf<Int, Float>() }
    var demonstrationOpacity by remember { mutableStateOf(1f) }
    var isDemonstrating by remember { mutableStateOf(false) }
    var demoJob by remember { mutableStateOf<Job?>(null) }
    var idleJob by remember { mutableStateOf<Job?>(null) }

    fun cancelDemonstration() {
        demoJob?.cancel()
        demoJob = null
        idleJob?.cancel()
        idleJob = null
        isDemonstrating = false
        if (mode == GuideStrokeMode.SINGLE) {
            strokeProgresses.clear()
        } else {
            val group = strokeInfo.activeGroup(currentStrokeIndex, mode)
            for (s in group) {
                strokeProgresses[s] = 1f
            }
        }
        demonstrationOpacity = 1f
    }

    fun startDemonstration() {
        if (isCompleted || currentStrokeIndex >= strokeInfo.strokes.size) {
            cancelDemonstration()
            return
        }
        cancelDemonstration()
        isDemonstrating = true
        demonstrationOpacity = 1f

        val group = strokeInfo.activeGroup(currentStrokeIndex, mode)
        val strokesToAnimate = group.filter { it >= currentStrokeIndex }
        if (strokesToAnimate.isEmpty()) {
            isDemonstrating = false
            return
        }
        for (s in strokesToAnimate) {
            strokeProgresses[s] = 0f
        }

        demoJob = scope.launch {
            if (mode == GuideStrokeMode.SINGLE) {
                val anim = Animatable(0f)
                anim.animateTo(
                    targetValue = 1f,
                    animationSpec = tween(durationMillis = 750, easing = FastOutSlowInEasing)
                ) {
                    strokeProgresses[currentStrokeIndex] = value
                }
                delay(200)
                val fadeAnim = Animatable(1f)
                fadeAnim.animateTo(
                    targetValue = 0f,
                    animationSpec = tween(durationMillis = 250)
                ) {
                    demonstrationOpacity = value
                }
                isDemonstrating = false
                strokeProgresses[currentStrokeIndex] = 0f
                demonstrationOpacity = 1f
            } else {
                for ((order, strokeIdx) in strokesToAnimate.withIndex()) {
                    if (order > 0) {
                        delay(40)
                    }
                    val anim = Animatable(0f)
                    anim.animateTo(
                        targetValue = 1f,
                        animationSpec = tween(durationMillis = 380, easing = FastOutSlowInEasing)
                    ) {
                        strokeProgresses[strokeIdx] = value
                    }
                }
                delay(50)
                isDemonstrating = false
                for (s in strokesToAnimate) {
                    strokeProgresses[s] = 1f
                }
            }

            idleJob?.cancel()
            idleJob = scope.launch {
                delay(4500)
                if (!isCompleted && currentStrokeIndex < strokeInfo.strokes.size && currentUserPoints.isEmpty()) {
                    matchedProgress = 0
                    hasReachedTarget = false
                    startDemonstration()
                }
            }
        }
    }

    fun startIdleTimer() {
        idleJob?.cancel()
        if (isCompleted || currentStrokeIndex >= strokeInfo.strokes.size) return
        idleJob = scope.launch {
            delay(4500)
            if (!isCompleted && currentStrokeIndex < strokeInfo.strokes.size && currentUserPoints.isEmpty()) {
                matchedProgress = 0
                hasReachedTarget = false
                startDemonstration()
            }
        }
    }

    LaunchedEffect(character, currentStrokeIndex, mode, isCompleted) {
        currentUserPoints.clear()
        matchedProgress = 0
        hasReachedTarget = false
        if (isCompleted) {
            cancelDemonstration()
        } else {
            val group = strokeInfo.activeGroup(currentStrokeIndex, mode)
            val isGroupStart = group.firstOrNull() == currentStrokeIndex
            if (mode == GuideStrokeMode.SINGLE || isGroupStart) {
                startDemonstration()
            } else {
                cancelDemonstration()
                startIdleTimer()
            }
        }
    }

    val backgroundPath = remember(character, strokeInfo, canvasSizePx) {
        if (strokeInfo.strokes.isNotEmpty()) {
            val combined = Path()
            for (svg in strokeInfo.strokes) {
                combined.addPath(StrokePathParser.parse(svg, logicalSize))
            }
            combined
        } else {
            NotoGlyphProvider.path(context, character, logicalSize)
        }
    }

    Box(modifier = modifier.size(canvasSizeDp)) {
        CalligraphyGridView(sizeDp = canvasSizeDp)

        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(character, currentStrokeIndex, isCompleted, mode, canvasSizePx) {
                    awaitEachGesture {
                        val down = awaitFirstDown(requireUnconsumed = false)
                        if (isCompleted || currentStrokeIndex >= strokeInfo.strokes.size) {
                            return@awaitEachGesture
                        }
                        if (isDemonstrating) {
                            cancelDemonstration()
                        } else {
                            idleJob?.cancel()
                        }

                        val median = strokeInfo.medianPoints(currentStrokeIndex, logicalSize)
                        val tolerance = StrokeMatcher.defaultTolerance * scaleFactor

                        fun processPoint(pt: Vec2) {
                            currentUserPoints.add(pt)
                            if (median.isNotEmpty()) {
                                val eval = StrokeMatcher.evaluateTouch(
                                    touchPoint = pt,
                                    median = median,
                                    currentProgress = matchedProgress,
                                    tolerance = tolerance
                                )
                                matchedProgress = eval.newProgress
                                if (eval.isCompleted) {
                                    hasReachedTarget = true
                                }
                            }
                        }

                        processPoint(Vec2(down.position.x, down.position.y))

                        do {
                            val event = awaitPointerEvent()
                            val change = event.changes.firstOrNull()
                            if (change != null && change.pressed) {
                                change.consume()
                                processPoint(Vec2(change.position.x, change.position.y))
                            }
                        } while (event.changes.any { it.pressed })

                        val pointsSnapshot = currentUserPoints.toList()
                        val acceptable = hasReachedTarget || StrokeSmoother.isStrokeAcceptable(
                            userPoints = pointsSnapshot,
                            median = median,
                            matchedProgress = matchedProgress
                        )

                        if (acceptable && pointsSnapshot.isNotEmpty()) {
                            val corrected = StrokeSmoother.smoothAndCorrect(
                                points = pointsSnapshot,
                                median = median,
                                maxCorrection = 7.0 * scaleFactor
                            )
                            val finishedIndex = currentStrokeIndex
                            view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
                            cancelDemonstration()

                            val updatedStrokes = completedUserStrokes + listOf(corrected)
                            onCompletedUserStrokesChange(updatedStrokes)
                            currentUserPoints.clear()
                            matchedProgress = 0
                            hasReachedTarget = false

                            onStrokeCompleted(finishedIndex)
                            if (updatedStrokes.size >= strokeInfo.strokes.size) {
                                onAllStrokesCompleted()
                            } else {
                                onCurrentStrokeIndexChange(currentStrokeIndex + 1)
                            }
                        } else {
                            currentUserPoints.clear()
                            matchedProgress = 0
                            hasReachedTarget = false
                            startIdleTimer()
                        }
                    }
                }
        ) {
            backgroundPath?.let { path ->
                drawPath(
                    path = path,
                    color = AppColors.BackgroundFontGray
                )
            }

            val strokeStyle = Stroke(
                width = strokeWidthPx,
                cap = StrokeCap.Round,
                join = StrokeJoin.Round
            )

            for (strokePoints in completedUserStrokes) {
                drawPath(
                    path = buildSmoothPath(strokePoints),
                    color = Color.Black,
                    style = strokeStyle
                )
            }

            if (!isCompleted) {
                val group = strokeInfo.activeGroup(currentStrokeIndex, mode)
                if (mode == GuideStrokeMode.SINGLE) {
                    if (isDemonstrating && currentStrokeIndex < strokeInfo.strokes.size) {
                        val median = strokeInfo.medianPoints(currentStrokeIndex, logicalSize)
                        val progress = strokeProgresses[currentStrokeIndex] ?: 0f
                        val fullPath = buildSmoothPath(median)
                        val trimmed = trimPath(fullPath, progress)
                        drawPath(
                            path = trimmed,
                            color = AppColors.guideColor(0, 1).copy(alpha = demonstrationOpacity),
                            style = strokeStyle
                        )
                    }
                } else {
                    for (strokeIdx in group.filter { it >= currentStrokeIndex }) {
                        val median = strokeInfo.medianPoints(strokeIdx, logicalSize)
                        val progress = if (isDemonstrating) (strokeProgresses[strokeIdx] ?: 0f) else 1f
                        val step = group.indexOf(strokeIdx).coerceAtLeast(0)
                        val color = AppColors.guideColor(step, group.size)
                        val fullPath = buildSmoothPath(median)
                        val trimmed = trimPath(fullPath, progress)
                        drawPath(
                            path = trimmed,
                            color = color,
                            style = strokeStyle
                        )
                    }
                }
            }

            if (currentUserPoints.isNotEmpty()) {
                drawPath(
                    path = buildSmoothPath(currentUserPoints),
                    color = Color.Black,
                    style = strokeStyle
                )
            }
        }
    }
}

private fun buildSmoothPath(points: List<Vec2>): Path {
    val path = Path()
    val first = points.firstOrNull() ?: return path
    path.moveTo(first.x.toFloat(), first.y.toFloat())
    when (points.size) {
        1 -> path.lineTo(first.x.toFloat(), first.y.toFloat())
        2 -> path.lineTo(points[1].x.toFloat(), points[1].y.toFloat())
        else -> {
            for (i in 1 until (points.size - 1)) {
                val midX = ((points[i].x + points[i + 1].x) / 2.0).toFloat()
                val midY = ((points[i].y + points[i + 1].y) / 2.0).toFloat()
                path.quadraticTo(
                    points[i].x.toFloat(),
                    points[i].y.toFloat(),
                    midX,
                    midY
                )
            }
            val last = points.last()
            path.lineTo(last.x.toFloat(), last.y.toFloat())
        }
    }
    return path
}

private fun trimPath(path: Path, progress: Float): Path {
    val clamped = progress.coerceIn(0f, 1f)
    if (clamped <= 0f) return Path()
    if (clamped >= 1f) return path

    val measure = PathMeasure(path.asAndroidPath(), false)
    val length = measure.length
    if (length <= 0f) return Path()

    val dst = android.graphics.Path()
    measure.getSegment(0f, length * clamped, dst, true)
    return dst.asComposePath()
}
