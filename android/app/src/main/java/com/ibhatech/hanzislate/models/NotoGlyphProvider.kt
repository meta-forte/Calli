package com.ibhatech.hanzislate.models

import android.content.Context
import android.graphics.Paint
import android.graphics.Typeface
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asComposePath
import kotlin.math.min

object NotoGlyphProvider {
    @Volatile
    private var cachedTypeface: Typeface? = null

    fun getTypeface(context: Context): Typeface? {
        cachedTypeface?.let { return it }
        return try {
            Typeface.createFromAsset(context.assets, "NotoSansSC.ttf").also {
                cachedTypeface = it
            }
        } catch (_: Exception) {
            null
        }
    }

    fun path(context: Context, character: String, canvasSize: CanvasSize): Path? {
        if (character.isEmpty()) return null
        val tf = getTypeface(context) ?: return null
        val side = min(canvasSize.width, canvasSize.height).toFloat()
        val offsetX = ((canvasSize.width - side) / 2.0).toFloat()
        val offsetY = ((canvasSize.height - side) / 2.0).toFloat()

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = tf
            textSize = side * 0.78f
        }

        val androidPath = android.graphics.Path()
        val x = offsetX + side * 0.11f
        val y = offsetY + side * 0.80f
        paint.getTextPath(character, 0, character.length, x, y, androidPath)
        if (androidPath.isEmpty) return null
        return androidPath.asComposePath()
    }
}
