package com.ibhatech.hanzislate.models

import kotlin.math.min
import kotlin.math.sqrt

data class TouchEvaluation(
    val newProgress: Int,
    val isCompleted: Boolean
)

object StrokeMatcher {
    const val defaultTolerance: Double = 55.0

    fun distance(p1: Vec2, p2: Vec2): Double {
        val dx = p1.x - p2.x
        val dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }

    fun evaluateTouch(
        touchPoint: Vec2,
        median: List<Vec2>,
        currentProgress: Int,
        tolerance: Double = defaultTolerance
    ): TouchEvaluation {
        if (median.isEmpty()) {
            return TouchEvaluation(0, true)
        }

        if (median.size == 1) {
            val dist = distance(touchPoint, median[0])
            val completed = dist <= tolerance
            return TouchEvaluation(if (completed) 1 else 0, completed)
        }

        var progress = currentProgress
        val targetIndex = min(progress, median.size - 1)
        val targetPoint = median[targetIndex]
        val distToTarget = distance(touchPoint, targetPoint)

        if (distToTarget <= tolerance) {
            progress = min(progress + 1, median.size)
        } else if (progress > 0 && progress < median.size) {
            val nextIndex = progress
            val distToNext = distance(touchPoint, median[nextIndex])
            if (distToNext <= tolerance) {
                progress = min(progress + 1, median.size)
            }
        }

        val isCompleted = progress >= median.size
        return TouchEvaluation(progress, isCompleted)
    }
}
