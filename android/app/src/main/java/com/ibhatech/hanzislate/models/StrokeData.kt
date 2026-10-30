package com.ibhatech.hanzislate.models

import kotlinx.serialization.Serializable
import kotlin.math.min

@Serializable
enum class GuideStrokeMode(val rawValue: String) {
    SINGLE("Single"),
    PAIRWISE("Pair"),
    COMPONENT("Component");

    val id: String
        get() = rawValue

    companion object {
        fun fromRawValue(value: String?): GuideStrokeMode {
            return entries.firstOrNull { it.rawValue == value } ?: SINGLE
        }
    }
}

data class StrokePair(
    val first: Int,
    val second: Int?
)

@Serializable
data class CharacterStrokeInfo(
    val strokes: List<String>,
    val medians: List<List<List<Double>>>,
    val components: List<List<Int>>? = null
) {
    fun medianPoints(strokeIndex: Int, canvasSize: CanvasSize): List<Vec2> {
        if (strokeIndex < 0 || strokeIndex >= medians.size) return emptyList()
        val strokeMedian = medians[strokeIndex]
        val side = min(canvasSize.width, canvasSize.height)
        val scale = side / 1024.0
        val offsetX = (canvasSize.width - side) / 2.0
        val offsetY = (canvasSize.height - side) / 2.0

        return strokeMedian.mapNotNull { point ->
            if (point.size < 2) return@mapNotNull null
            val x = point[0]
            val y = point[1]
            val screenX = offsetX + x * scale
            val screenY = offsetY + (900.0 - y) * scale
            Vec2(screenX, screenY)
        }
    }

    fun activeGroup(strokeIndex: Int, mode: GuideStrokeMode): List<Int> {
        if (strokeIndex < 0 || strokeIndex >= strokes.size) return emptyList()
        return when (mode) {
            GuideStrokeMode.SINGLE -> listOf(strokeIndex)
            GuideStrokeMode.PAIRWISE -> {
                val first = (strokeIndex / 2) * 2
                val second = first + 1
                if (second < strokes.size) {
                    listOf(first, second)
                } else {
                    listOf(first)
                }
            }
            GuideStrokeMode.COMPONENT -> {
                val comps = components
                if (!comps.isNullOrEmpty()) {
                    for (group in comps) {
                        if (group.contains(strokeIndex)) {
                            return group
                        }
                    }
                }
                listOf(strokeIndex)
            }
        }
    }

    fun activePair(strokeIndex: Int): StrokePair? {
        if (strokeIndex < 0 || strokeIndex >= strokes.size) return null
        val first = (strokeIndex / 2) * 2
        val secondCandidate = first + 1
        val second = if (secondCandidate < strokes.size) secondCandidate else null
        return StrokePair(first = first, second = second)
    }
}
