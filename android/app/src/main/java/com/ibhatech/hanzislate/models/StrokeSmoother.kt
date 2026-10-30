package com.ibhatech.hanzislate.models

import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

object StrokeSmoother {
    fun smoothAndCorrect(
        points: List<Vec2>,
        median: List<Vec2>,
        blendFactor: Double = 0.35,
        maxCorrection: Double = 7.0
    ): List<Vec2> {
        if (points.size < 2) return points

        val filtered = mutableListOf(points[0])
        for (pt in points.drop(1)) {
            val last = filtered.last()
            val dx = pt.x - last.x
            val dy = pt.y - last.y
            if ((dx * dx + dy * dy) >= 4.0) {
                filtered.add(pt)
            }
        }
        if (filtered.size < 2) return points

        var smoothed: List<Vec2> = filtered
        if (smoothed.size >= 3) {
            val passes = 2
            repeat(passes) {
                val temp = smoothed.toMutableList()
                for (i in 1 until (smoothed.size - 1)) {
                    val prev = smoothed[i - 1]
                    val curr = smoothed[i]
                    val next = smoothed[i + 1]
                    temp[i] = Vec2(
                        x = prev.x * 0.25 + curr.x * 0.5 + next.x * 0.25,
                        y = prev.y * 0.25 + curr.y * 0.5 + next.y * 0.25
                    )
                }
                smoothed = temp
            }
        }

        if (median.isEmpty() || smoothed.size < 3) return smoothed

        val corrected = smoothed.toMutableList()
        for (i in 1 until (smoothed.size - 1)) {
            val pt = smoothed[i]
            val closest = closestPointOnPolyline(pt, polyline = median)
            val dx = closest.x - pt.x
            val dy = closest.y - pt.y
            val dist = sqrt(dx * dx + dy * dy)

            if (dist > 0.0 && dist < 50.0) {
                val correctionDist = min(dist * blendFactor, maxCorrection)
                val ratio = correctionDist / dist
                corrected[i] = Vec2(
                    x = pt.x + dx * ratio,
                    y = pt.y + dy * ratio
                )
            }
        }

        return corrected
    }

    fun isStrokeAcceptable(
        userPoints: List<Vec2>,
        median: List<Vec2>,
        matchedProgress: Int
    ): Boolean {
        if (userPoints.isEmpty() || median.isEmpty()) return false

        if (matchedProgress >= median.size) {
            return true
        }

        if (median.size <= 2) {
            return matchedProgress >= 1
        }

        val required = max(1, (median.size.toDouble() * 0.6).toInt())
        if (matchedProgress >= required) {
            val userLength = pathLength(points = userPoints)
            val medianLength = pathLength(points = median)
            if (userLength >= medianLength * 0.35) {
                return true
            }
        }

        return false
    }

    fun pathLength(points: List<Vec2>): Double {
        if (points.size <= 1) return 0.0
        var total = 0.0
        for (i in 1 until points.size) {
            val p1 = points[i - 1]
            val p2 = points[i]
            val dx = p2.x - p1.x
            val dy = p2.y - p1.y
            total += sqrt(dx * dx + dy * dy)
        }
        return total
    }

    fun closestPointOnPolyline(pt: Vec2, polyline: List<Vec2>): Vec2 {
        if (polyline.size < 2) return polyline.firstOrNull() ?: pt
        var bestPoint = polyline[0]
        var minDistanceSq = Double.MAX_VALUE

        for (i in 0 until (polyline.size - 1)) {
            val p1 = polyline[i]
            val p2 = polyline[i + 1]
            val proj = projectPointOnSegment(pt, a = p1, b = p2)
            val dx = pt.x - proj.x
            val dy = pt.y - proj.y
            val distSq = dx * dx + dy * dy
            if (distSq < minDistanceSq) {
                minDistanceSq = distSq
                bestPoint = proj
            }
        }
        return bestPoint
    }

    fun projectPointOnSegment(p: Vec2, a: Vec2, b: Vec2): Vec2 {
        val abx = b.x - a.x
        val aby = b.y - a.y
        val apx = p.x - a.x
        val apy = p.y - a.y
        val abLenSq = abx * abx + aby * aby
        if (abLenSq == 0.0) return a
        val t = max(0.0, min(1.0, (apx * abx + apy * aby) / abLenSq))
        return Vec2(x = a.x + t * abx, y = a.y + t * aby)
    }
}
