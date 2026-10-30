package com.ibhatech.hanzislate.models

enum class GridCellSize(val rawValue: String) {
    SMALL("small"),
    MEDIUM("medium"),
    LARGE("large");

    val id: String
        get() = rawValue

    val title: String
        get() = when (this) {
            SMALL -> "Small"
            MEDIUM -> "Medium"
            LARGE -> "Large"
        }

    val hanziFontSize: Float
        get() = when (this) {
            SMALL -> 20f
            MEDIUM -> 26f
            LARGE -> 34f
        }

    val pinyinFontSize: Float
        get() = when (this) {
            SMALL -> 11f
            MEDIUM -> 13f
            LARGE -> 15f
        }

    val meaningFontSize: Float
        get() = when (this) {
            SMALL -> 9.5f
            MEDIUM -> 11f
            LARGE -> 12.5f
        }

    val minimumCellWidth: Float
        get() = when (this) {
            SMALL -> 60f
            MEDIUM -> 76f
            LARGE -> 100f
        }

    val cellHeight: Float
        get() = when (this) {
            SMALL -> 62f
            MEDIUM -> 78f
            LARGE -> 100f
        }

    val searchCellHeight: Float
        get() = when (this) {
            SMALL -> 76f
            MEDIUM -> 92f
            LARGE -> 116f
        }

    val cornerRadius: Float
        get() = when (this) {
            SMALL -> 10f
            MEDIUM -> 12f
            LARGE -> 14f
        }

    companion object {
        const val storageKey = "kGridCellSize"
        val defaultSize: GridCellSize = MEDIUM
        const val gridSpacing: Float = 10f

        fun fromRawValue(value: String?): GridCellSize {
            return entries.firstOrNull { it.rawValue == value } ?: defaultSize
        }
    }
}
