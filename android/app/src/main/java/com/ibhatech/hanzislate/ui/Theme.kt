package com.ibhatech.hanzislate.ui

import androidx.compose.ui.graphics.Color

object AppColors {
    val AppBackground = Color(239f / 255f, 239f / 255f, 239f / 255f, 1f)
    val CardBackground = Color(0.96f, 0.96f, 0.96f, 1f)
    val PrimaryText = Color(0.12f, 0.12f, 0.12f, 1f)
    val SecondaryText = Color(0.42f, 0.42f, 0.42f, 1f)
    val TertiaryText = Color(0.35f, 0.35f, 0.35f, 1f)
    val BorderGray = Color(0.85f, 0.85f, 0.85f, 1f)
    val AccentBlue = Color(0f, 0.478f, 1f, 1f)
    val AccentGreen = Color(0.20f, 0.78f, 0.35f, 1f)
    val AccentOrange = Color(1f, 0.58f, 0f, 1f)
    val BackgroundFontGray = Color(0.70f, 0.70f, 0.72f, 1f)

    fun guideColor(step: Int, totalSteps: Int): Color {
        val brightness = if (totalSteps <= 1) {
            0.90f
        } else {
            val fraction = step.toFloat() / (totalSteps - 1).toFloat()
            0.90f - fraction * (0.90f - 0.48f)
        }
        return Color.hsv(
            hue = 0.598f * 360f,
            saturation = 0.83f,
            value = brightness
        )
    }
}
