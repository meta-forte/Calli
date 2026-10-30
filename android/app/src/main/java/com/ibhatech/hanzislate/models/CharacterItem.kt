package com.ibhatech.hanzislate.models

import kotlinx.serialization.Serializable

@Serializable
data class CharacterItem(
    val id: Int,
    val level: Int,
    val hanzi: String,
    val pinyin: String,
    val tones: String,
    val meaning: String,
    val exampleChinese: String,
    val examplePinyin: String,
    val exampleEnglish: String
) {
    val isHSK: Boolean
        get() = hskLevels.contains(level)

    val levelTitle: String
        get() = title(forLevel = level)

    companion object {
        const val othersLevel = 0
        val hskLevels: IntRange = 1..9

        fun title(forLevel: Int): String {
            return if (hskLevels.contains(forLevel)) "HSK $forLevel" else "Others"
        }

        fun levelPrecedes(lhs: Int, rhs: Int): Boolean {
            val lhsIsHSK = hskLevels.contains(lhs)
            val rhsIsHSK = hskLevels.contains(rhs)
            if (lhsIsHSK != rhsIsHSK) {
                return lhsIsHSK
            }
            return lhs < rhs
        }
    }
}
