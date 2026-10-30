package com.ibhatech.hanzislate.models

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import java.io.File

interface PreferenceStore {
    fun getInt(key: String, defaultValue: Int): Int
    fun putInt(key: String, value: Int)
    fun getString(key: String, defaultValue: String): String
    fun putString(key: String, value: String)
    fun getDouble(key: String, defaultValue: Double): Double
    fun putDouble(key: String, value: Double)
}

class InMemoryPreferenceStore(
    initialInts: Map<String, Int> = emptyMap(),
    initialStrings: Map<String, String> = emptyMap(),
    initialDoubles: Map<String, Double> = emptyMap()
) : PreferenceStore {
    private val ints = initialInts.toMutableMap()
    private val strings = initialStrings.toMutableMap()
    private val doubles = initialDoubles.toMutableMap()

    override fun getInt(key: String, defaultValue: Int): Int = ints[key] ?: defaultValue
    override fun putInt(key: String, value: Int) { ints[key] = value }
    override fun getString(key: String, defaultValue: String): String = strings[key] ?: defaultValue
    override fun putString(key: String, value: String) { strings[key] = value }
    override fun getDouble(key: String, defaultValue: Double): Double = doubles[key] ?: defaultValue
    override fun putDouble(key: String, value: Double) { doubles[key] = value }
}

class SharedPreferencesStore(context: Context) : PreferenceStore {
    private val prefs = context.getSharedPreferences("hanzislate_prefs", Context.MODE_PRIVATE)

    override fun getInt(key: String, defaultValue: Int): Int = prefs.getInt(key, defaultValue)
    override fun putInt(key: String, value: Int) { prefs.edit().putInt(key, value).apply() }
    override fun getString(key: String, defaultValue: String): String = prefs.getString(key, defaultValue) ?: defaultValue
    override fun putString(key: String, value: String) { prefs.edit().putString(key, value).apply() }
    override fun getDouble(key: String, defaultValue: Double): Double =
        Double.fromBits(prefs.getLong(key, defaultValue.toBits()))
    override fun putDouble(key: String, value: Double) {
        prefs.edit().putLong(key, value.toBits()).apply()
    }
}

fun interface ResourceLoader {
    fun loadText(fileName: String): String?
}

class AssetResourceLoader(private val context: Context) : ResourceLoader {
    override fun loadText(fileName: String): String? {
        return try {
            context.assets.open(fileName).bufferedReader(Charsets.UTF_8).use { it.readText() }
        } catch (_: Exception) {
            null
        }
    }
}

class FileResourceLoader(private val baseDir: File = resolveDefaultResourcesDir()) : ResourceLoader {
    override fun loadText(fileName: String): String? {
        val file = File(baseDir, fileName)
        return if (file.exists()) file.readText(Charsets.UTF_8) else null
    }

    companion object {
        fun resolveDefaultResourcesDir(): File {
            val candidates = listOf(
                File("Calli/Resources"),
                File("../Calli/Resources"),
                File("../../Calli/Resources")
            )
            return candidates.firstOrNull { it.exists() && it.isDirectory } ?: File("Calli/Resources")
        }
    }
}

class CharacterStore(
    private val prefs: PreferenceStore = InMemoryPreferenceStore(),
    private val resourceLoader: ResourceLoader = FileResourceLoader(),
    loadBundledData: Boolean = true,
    preloadOtherStrokesAsync: Boolean = true
) {
    private val json = Json { ignoreUnknownKeys = true }
    private val bgScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val otherStrokeLock = Any()

    var allCharacters: List<CharacterItem> = emptyList()
        private set

    var otherCharacters: List<CharacterItem> = emptyList()
        private set

    private val _sections = MutableStateFlow<List<CharacterSection>>(emptyList())
    val sectionsFlow: StateFlow<List<CharacterSection>> = _sections.asStateFlow()
    val sections: List<CharacterSection>
        get() = _sections.value

    private val _matchedMeanings = MutableStateFlow<Map<Int, String>>(emptyMap())
    val matchedMeaningsFlow: StateFlow<Map<Int, String>> = _matchedMeanings.asStateFlow()
    val matchedMeanings: Map<Int, String>
        get() = _matchedMeanings.value

    private val _isLoading = MutableStateFlow(false)
    val isLoadingFlow: StateFlow<Boolean> = _isLoading.asStateFlow()
    val isLoading: Boolean
        get() = _isLoading.value

    private val _selectedLevel = MutableStateFlow(
        clampedLevel(prefs.getInt(selectedLevelStorageKey, defaultLevel))
    )
    val selectedLevelFlow: StateFlow<Int> = _selectedLevel.asStateFlow()
    var selectedLevel: Int
        get() = _selectedLevel.value
        set(value) {
            val clamped = clampedLevel(value)
            _selectedLevel.value = clamped
            prefs.putInt(selectedLevelStorageKey, clamped)
            refreshSections()
        }

    private val _searchQuery = MutableStateFlow("")
    val searchQueryFlow: StateFlow<String> = _searchQuery.asStateFlow()
    var searchQuery: String
        get() = _searchQuery.value
        set(value) {
            _searchQuery.value = value
            refreshSections()
        }

    private var searchIndex = CharacterSearchIndex(emptyList())
    private var strokeDatabase: Map<String, CharacterStrokeInfo> = emptyMap()
    private var otherStrokeDatabase: Map<String, CharacterStrokeInfo>? = null

    val availableLevels: List<Int>
        get() = CharacterItem.hskLevels.toList()

    val isSearching: Boolean
        get() = _searchQuery.value.trim().isNotEmpty()

    val displayedCharacters: List<CharacterItem>
        get() = _sections.value.flatMap { it.characters }

    val displayedCount: Int
        get() = _sections.value.sumOf { it.characters.size }

    init {
        if (loadBundledData) {
            loadData(preloadOtherStrokesAsync = preloadOtherStrokesAsync)
        }
    }

    fun matchedMeaning(forItem: CharacterItem): String? {
        if (!isSearching) return null
        return _matchedMeanings.value[forItem.id]
    }

    fun strokeInfo(forHanzi: String): CharacterStrokeInfo? {
        strokeDatabase[forHanzi]?.let { return it }
        synchronized(otherStrokeLock) {
            loadOtherStrokesIfNeededLocked()
            return otherStrokeDatabase?.get(forHanzi)
        }
    }

    fun loadFromDirectData(
        characters: List<CharacterItem>,
        strokes: Map<String, CharacterStrokeInfo>,
        others: List<CharacterItem> = emptyList(),
        otherStrokes: Map<String, CharacterStrokeInfo> = emptyMap()
    ) {
        allCharacters = characters
        otherCharacters = others
        strokeDatabase = strokes
        synchronized(otherStrokeLock) {
            otherStrokeDatabase = otherStrokes
        }
        rebuildIndex()
    }

    private fun refreshSections() {
        if (isSearching) {
            val result = searchIndex.searchWithContext(_searchQuery.value)
            _sections.value = result.sections
            _matchedMeanings.value = result.matchedMeanings
        } else {
            val level = _selectedLevel.value
            val levelCharacters = allCharacters.filter { it.level == level }
            _sections.value = listOf(CharacterSection(level = level, characters = levelCharacters))
            _matchedMeanings.value = emptyMap()
        }
    }

    private fun rebuildIndex() {
        searchIndex = CharacterSearchIndex(allCharacters + otherCharacters)
        refreshSections()
    }

    private fun loadData(preloadOtherStrokesAsync: Boolean) {
        _isLoading.value = true
        try {
            allCharacters = resourceLoader.loadText("characters.json")?.let {
                runCatching { json.decodeFromString<List<CharacterItem>>(it) }.getOrNull()
            } ?: emptyList()

            otherCharacters = resourceLoader.loadText("others.json")?.let {
                runCatching { json.decodeFromString<List<CharacterItem>>(it) }.getOrNull()
            } ?: emptyList()

            strokeDatabase = resourceLoader.loadText("strokes.json")?.let {
                runCatching { json.decodeFromString<Map<String, CharacterStrokeInfo>>(it) }.getOrNull()
            } ?: emptyMap()

            rebuildIndex()

            if (preloadOtherStrokesAsync) {
                bgScope.launch {
                    synchronized(otherStrokeLock) {
                        loadOtherStrokesIfNeededLocked()
                    }
                }
            }
        } finally {
            _isLoading.value = false
        }
    }

    private fun loadOtherStrokesIfNeededLocked() {
        if (otherStrokeDatabase != null) return
        otherStrokeDatabase = resourceLoader.loadText("others_strokes.json")?.let {
            runCatching { json.decodeFromString<Map<String, CharacterStrokeInfo>>(it) }.getOrNull()
        } ?: emptyMap()
    }

    companion object {
        const val selectedLevelStorageKey = "kSelectedHSKLevel"
        const val defaultLevel = 1

        fun clampedLevel(level: Int): Int {
            return level.coerceIn(CharacterItem.hskLevels.first, CharacterItem.hskLevels.last)
        }
    }
}
