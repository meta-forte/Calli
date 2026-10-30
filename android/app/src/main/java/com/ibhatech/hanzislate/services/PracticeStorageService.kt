package com.ibhatech.hanzislate.services

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class PracticeStorageService(private val databaseFile: File? = null) {
    private val inMemoryCounts = mutableMapOf<Pair<String, String>, Int>()
    private var db: SQLiteDatabase? = null

    init {
        val file = databaseFile
        if (file != null) {
            runCatching {
                file.parentFile?.mkdirs()
                db = SQLiteDatabase.openOrCreateDatabase(file, null)
                db?.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS practice_log (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        character TEXT NOT NULL,
                        date TEXT NOT NULL,
                        practice_count INTEGER NOT NULL DEFAULT 1,
                        UNIQUE(character, date)
                    );
                    """.trimIndent()
                )
            }
        }
    }

    fun recordPractice(character: String, date: String = currentDateString()): Int {
        val sqlite = db
        if (sqlite != null) {
            val current = getPracticeCount(character, date)
            if (current == 0) {
                sqlite.execSQL(
                    "INSERT INTO practice_log (character, date, practice_count) VALUES (?, ?, 1);",
                    arrayOf<Any>(character, date)
                )
            } else {
                sqlite.execSQL(
                    "UPDATE practice_log SET practice_count = practice_count + 1 WHERE character = ? AND date = ?;",
                    arrayOf<Any>(character, date)
                )
            }
            return getPracticeCount(character, date)
        }

        val key = character to date
        val updated = (inMemoryCounts[key] ?: 0) + 1
        inMemoryCounts[key] = updated
        return updated
    }

    fun getPracticeCount(character: String, date: String = currentDateString()): Int {
        val sqlite = db
        if (sqlite != null) {
            sqlite.rawQuery(
                "SELECT practice_count FROM practice_log WHERE character = ? AND date = ?;",
                arrayOf(character, date)
            ).use { cursor ->
                if (cursor.moveToFirst()) {
                    return cursor.getInt(0)
                }
            }
            return 0
        }
        return inMemoryCounts[character to date] ?: 0
    }

    fun getTotalPracticeCount(character: String): Int {
        val sqlite = db
        if (sqlite != null) {
            sqlite.rawQuery(
                "SELECT SUM(practice_count) FROM practice_log WHERE character = ?;",
                arrayOf(character)
            ).use { cursor ->
                if (cursor.moveToFirst() && !cursor.isNull(0)) {
                    return cursor.getInt(0)
                }
            }
            return 0
        }
        return inMemoryCounts.entries
            .filter { it.key.first == character }
            .sumOf { it.value }
    }

    fun getAllPracticeCountsForToday(date: String = currentDateString()): Map<String, Int> {
        val sqlite = db
        if (sqlite != null) {
            val result = mutableMapOf<String, Int>()
            sqlite.rawQuery(
                "SELECT character, practice_count FROM practice_log WHERE date = ?;",
                arrayOf(date)
            ).use { cursor ->
                while (cursor.moveToNext()) {
                    result[cursor.getString(0)] = cursor.getInt(1)
                }
            }
            return result
        }
        return inMemoryCounts.entries
            .filter { it.key.second == date }
            .associate { it.key.first to it.value }
    }

    fun close() {
        db?.close()
        db = null
    }

    companion object {
        private val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

        fun currentDateString(): String {
            return LocalDate.now().format(formatter)
        }

        fun create(context: Context): PracticeStorageService {
            val file = File(context.filesDir, "practice.sqlite")
            return PracticeStorageService(file)
        }
    }
}
