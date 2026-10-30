package com.ibhatech.hanzislate.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun CalligraphyGridView(
    sizeDp: Dp,
    modifier: Modifier = Modifier
) {
    Canvas(
        modifier = modifier
            .size(sizeDp)
            .clip(RoundedCornerShape(12.dp))
            .background(Color.White)
    ) {
        val w = size.width
        val h = size.height
        val dashEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx()), 0f)

        drawLine(
            color = Color.Red.copy(alpha = 0.20f),
            start = Offset(0f, 0f),
            end = Offset(w, h),
            strokeWidth = 1.dp.toPx(),
            pathEffect = dashEffect
        )
        drawLine(
            color = Color.Red.copy(alpha = 0.20f),
            start = Offset(w, 0f),
            end = Offset(0f, h),
            strokeWidth = 1.dp.toPx(),
            pathEffect = dashEffect
        )

        drawLine(
            color = Color.Red.copy(alpha = 0.30f),
            start = Offset(0f, h / 2f),
            end = Offset(w, h / 2f),
            strokeWidth = 1.dp.toPx(),
            pathEffect = dashEffect
        )
        drawLine(
            color = Color.Red.copy(alpha = 0.30f),
            start = Offset(w / 2f, 0f),
            end = Offset(w / 2f, h),
            strokeWidth = 1.dp.toPx(),
            pathEffect = dashEffect
        )

        drawRoundRect(
            color = Color.Red.copy(alpha = 0.35f),
            cornerRadius = CornerRadius(12.dp.toPx(), 12.dp.toPx()),
            style = Stroke(width = 2.dp.toPx())
        )
    }
}
