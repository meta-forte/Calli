package com.ibhatech.hanzislate

import com.ibhatech.hanzislate.models.CanvasSize
import com.ibhatech.hanzislate.models.CharacterItem
import com.ibhatech.hanzislate.models.CharacterSection
import com.ibhatech.hanzislate.models.CharacterStore
import com.ibhatech.hanzislate.models.CharacterStrokeInfo
import com.ibhatech.hanzislate.models.GridCellSize
import com.ibhatech.hanzislate.models.GuideStrokeMode
import com.ibhatech.hanzislate.models.InMemoryPreferenceStore
import com.ibhatech.hanzislate.models.PinyinSyllable
import com.ibhatech.hanzislate.models.StrokeMatcher
import com.ibhatech.hanzislate.models.StrokePathParser
import com.ibhatech.hanzislate.models.StrokeSmoother
import com.ibhatech.hanzislate.models.Vec2
import com.ibhatech.hanzislate.services.AppUpdateInfo
import com.ibhatech.hanzislate.services.AppUpdateService
import com.ibhatech.hanzislate.services.AppVersion
import com.ibhatech.hanzislate.services.PracticeStorageService
import com.ibhatech.hanzislate.services.PropertyConfig
import com.ibhatech.hanzislate.ui.CharacterDetailConfig
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import kotlin.math.abs

class HanziSlateUnitTests {
    private lateinit var prefs: InMemoryPreferenceStore
    private lateinit var store: CharacterStore

    @Before
    fun setUp() {
        prefs = InMemoryPreferenceStore()
        store = CharacterStore(
            prefs = prefs,
            loadBundledData = true,
            preloadOtherStrokesAsync = false
        )
    }

    private fun results(forQuery: String): List<CharacterSection> {
        store.searchQuery = forQuery
        return store.sections
    }

    private fun hanzi(sections: List<CharacterSection>): Set<String> {
        return sections.flatMap { it.characters }.map { it.hanzi }.toSet()
    }

    private fun readings(item: CharacterItem): List<PinyinSyllable> {
        return item.pinyin.split(",").mapNotNull { PinyinSyllable.parse(it.trim()) }
    }

    @Test
    fun testBundledDataIncludesOtherCharacters() {
        assertEquals(3088, store.allCharacters.size)
        assertTrue(store.otherCharacters.size > 6000)
        assertTrue(store.otherCharacters.all { it.level == CharacterItem.othersLevel })
        val hskHanzi = store.allCharacters.map { it.hanzi }.toSet()
        assertTrue(store.otherCharacters.all { !hskHanzi.contains(it.hanzi) })
    }

    @Test
    fun testFuMatchesPinyinInsteadOfEnglishSubstrings() {
        val sections = results("Fu")
        val found = hanzi(sections)

        assertTrue(found.contains("服"))
        assertTrue(found.contains("父"))
        assertFalse(found.contains("乐"))
        assertFalse(found.contains("安"))
        assertFalse(found.contains("饱"))
        assertFalse(found.contains("满"))
        assertFalse(found.contains("毛"))
        assertFalse(found.contains("将"))
        assertFalse(found.contains("况"))

        for (section in sections) {
            val first = section.characters.firstOrNull()
            assertNotNull(first)
            assertTrue(readings(first!!).any { it.base == "fu" })
        }
    }

    @Test
    fun testSonMatchesExactWordAndNotSong() {
        val sections = results("Son")
        val found = hanzi(sections)

        assertTrue(found.contains("子"))
        assertTrue(found.contains("儿"))
        assertFalse(found.contains("唱"))
        assertFalse(found.contains("松"))

        val zi = sections.flatMap { it.characters }.firstOrNull { it.hanzi == "子" }
        assertNotNull(zi)
        assertEquals("son", store.matchedMeaning(zi!!))
    }

    @Test
    fun testIrregularAndRegularPluralLemmasMatchBothWays() {
        val leafFound = hanzi(results("leaf"))
        val leavesFound = hanzi(results("leaves"))

        assertEquals(leafFound, leavesFound)
        assertTrue(leafFound.contains("叶"))
        assertTrue(leafFound.contains("页"))
        assertTrue(leafFound.contains("茗"))
        assertTrue(leafFound.contains("菸"))

        val ming = store.displayedCharacters.firstOrNull { it.hanzi == "茗" }
        assertNotNull(ming)
        assertEquals("tea leaves", store.matchedMeaning(ming!!))

        val featherFound = hanzi(results("feather"))
        val feathersFound = hanzi(results("feathers"))
        assertTrue(featherFound.contains("毛"))
        assertTrue(feathersFound.contains("毛"))
        assertEquals(featherFound, feathersFound)
    }

    @Test
    fun testSearchSpansAllLevelsAndGroupsInOrderWithOthersLast() {
        store.selectedLevel = 3
        val sections = results("fu")
        val levels = sections.map { it.level }

        assertEquals(CharacterItem.othersLevel, levels.last())
        assertEquals(levels.dropLast(1).sorted(), levels.dropLast(1))
        assertTrue(levels.contains(1))
        assertTrue(levels.contains(4))
        assertEquals("Others", sections.last().title)
        assertEquals("HSK ${levels[0]}", sections.first().title)
    }

    @Test
    fun testToneNumberNarrowsResults() {
        val sections = results("fu4")
        val found = hanzi(sections)

        assertTrue(found.contains("父"))
        assertFalse(found.contains("服"))
        for (item in sections.flatMap { it.characters }) {
            assertTrue(readings(item).any { it.base == "fu" && it.tone == 4 })
        }
    }

    @Test
    fun testToneMarkInQueryNarrowsResults() {
        val found = hanzi(results("fú"))
        assertTrue(found.contains("服"))
        assertFalse(found.contains("父"))
    }

    @Test
    fun testUmlautSpellings() {
        assertTrue(hanzi(results("lü")).contains("绿"))
        assertTrue(hanzi(results("lv4")).contains("绿"))
        assertFalse(hanzi(results("lv4")).contains("路"))
        val lu4 = hanzi(results("lu4"))
        assertTrue(lu4.contains("绿") && lu4.contains("路"))
    }

    @Test
    fun testPartialSyllableMatchesWhileTyping() {
        assertTrue(hanzi(results("zh")).contains("中"))
        assertTrue(hanzi(results("zhon")).contains("中"))
    }

    @Test
    fun testPrepositionForEliminatesMeasureWordsAndPhrases() {
        val sections = results("for")
        val found = hanzi(sections)

        assertFalse(found.contains("杯"))
        assertFalse(found.contains("本"))
        assertFalse(found.contains("备"))
        assertFalse(found.contains("被"))
        assertFalse(found.contains("件"))
        assertFalse(found.contains("间"))
        assertFalse(found.contains("满"))

        for (item in sections.flatMap { it.characters }) {
            assertEquals("for", store.matchedMeaning(item)?.lowercase())
        }
    }

    @Test
    fun testMeaningMatchesWholeWordsAndWordStartsOnly() {
        assertTrue(hanzi(results("love")).contains("爱"))
        assertTrue(hanzi(results("cheer")).contains("乐"))
        assertTrue(hanzi(results("to love")).contains("爱"))
        assertFalse(hanzi(results("erful")).contains("乐"))
    }

    @Test
    fun testHanziQueryMatchesEachCharacter() {
        val sections = results("你好")
        assertEquals(setOf("你", "好"), hanzi(sections))
        assertEquals(listOf(1), sections.map { it.level })
    }

    @Test
    fun testCharacterOutsideHSKAppearsInOthers() {
        val sections = results("愛")
        assertEquals(1, sections.size)
        val section = sections.first()
        assertEquals("Others", section.title)
        assertEquals(listOf("愛"), section.characters.map { it.hanzi })

        val strokes = store.strokeInfo("愛")
        assertNotNull(strokes)
        assertEquals(13, strokes!!.strokes.size)
    }

    @Test
    fun testClearingSearchShowsSelectedLevel() {
        store.selectedLevel = 3
        results("fu")
        store.searchQuery = "   "

        assertFalse(store.isSearching)
        assertEquals(listOf(3), store.sections.map { it.level })
        assertEquals(283, store.displayedCount)
    }

    @Test
    fun testNoResults() {
        assertTrue(results("qqqqzz").isEmpty())
        assertEquals(0, store.displayedCount)
    }

    @Test
    fun testSelectedLevelPersistsAndClamps() {
        assertEquals(CharacterStore.defaultLevel, store.selectedLevel)
        store.selectedLevel = 3
        assertEquals(3, prefs.getInt(CharacterStore.selectedLevelStorageKey, 1))

        val relaunched = CharacterStore(prefs = prefs, loadBundledData = false)
        assertEquals(3, relaunched.selectedLevel)

        prefs.putInt(CharacterStore.selectedLevelStorageKey, 42)
        assertEquals(9, CharacterStore(prefs = prefs, loadBundledData = false).selectedLevel)

        store.selectedLevel = 0
        assertEquals(1, store.selectedLevel)
    }

    @Test
    fun testPinyinSyllableParsing() {
        assertEquals(PinyinSyllable("fu", 4), PinyinSyllable.parse("fù"))
        assertEquals(PinyinSyllable("fu", 2), PinyinSyllable.parse("FU2"))
        assertEquals(PinyinSyllable("lv", 4), PinyinSyllable.parse("lǜ"))
        assertEquals(PinyinSyllable("lv", 3), PinyinSyllable.parse("lu:3"))
        assertEquals(PinyinSyllable("ma", null), PinyinSyllable.parse("ma"))
        assertNull(PinyinSyllable.parse("4"))
        assertNull(PinyinSyllable.parse("爱"))
    }

    @Test
    fun testPairwiseAndComponentGroups() {
        val dummyStrokes = List(9) { "M 0 0 L 10 10" }
        val dummyMedians = List(9) { listOf(listOf(0.0, 0.0), listOf(10.0, 10.0)) }
        val components = listOf(listOf(0, 1, 2), listOf(3, 4), listOf(5, 6, 7, 8))
        val strokeInfo = CharacterStrokeInfo(strokes = dummyStrokes, medians = dummyMedians, components = components)

        assertEquals(listOf(0), strokeInfo.activeGroup(0, GuideStrokeMode.SINGLE))
        assertEquals(listOf(8), strokeInfo.activeGroup(8, GuideStrokeMode.SINGLE))
        assertEquals(emptyList<Int>(), strokeInfo.activeGroup(9, GuideStrokeMode.SINGLE))

        assertEquals(listOf(0, 1), strokeInfo.activeGroup(0, GuideStrokeMode.PAIRWISE))
        assertEquals(listOf(0, 1), strokeInfo.activeGroup(1, GuideStrokeMode.PAIRWISE))
        assertEquals(listOf(8), strokeInfo.activeGroup(8, GuideStrokeMode.PAIRWISE))

        assertEquals(listOf(0, 1, 2), strokeInfo.activeGroup(1, GuideStrokeMode.COMPONENT))
        assertEquals(listOf(3, 4), strokeInfo.activeGroup(4, GuideStrokeMode.COMPONENT))
        assertEquals(listOf(5, 6, 7, 8), strokeInfo.activeGroup(8, GuideStrokeMode.COMPONENT))
    }

    @Test
    fun testStrokeMatcher() {
        val median = listOf(Vec2(10, 50), Vec2(50, 50), Vec2(90, 50))
        val res1 = StrokeMatcher.evaluateTouch(Vec2(12, 52), median, 0)
        assertEquals(1, res1.newProgress)
        assertFalse(res1.isCompleted)

        val res2 = StrokeMatcher.evaluateTouch(Vec2(50, 50), median, res1.newProgress)
        assertEquals(2, res2.newProgress)
        assertFalse(res2.isCompleted)

        val res3 = StrokeMatcher.evaluateTouch(Vec2(88, 51), median, res2.newProgress)
        assertEquals(3, res3.newProgress)
        assertTrue(res3.isCompleted)

        val distant = StrokeMatcher.evaluateTouch(Vec2(200, 200), median, 0)
        assertEquals(0, distant.newProgress)
        assertFalse(distant.isCompleted)
    }

    @Test
    fun testStrokeSmoother() {
        val userPoints = listOf(
            Vec2(10, 50),
            Vec2(20, 55),
            Vec2(30, 45),
            Vec2(40, 55),
            Vec2(50, 45),
            Vec2(60, 50)
        )
        val median = listOf(Vec2(10, 50), Vec2(60, 50))
        val smoothed = StrokeSmoother.smoothAndCorrect(userPoints, median)
        assertEquals(userPoints.size, smoothed.size)
        for (i in 1 until (smoothed.size - 1)) {
            assertTrue(abs(smoothed[i].y - 50.0) < 3.5)
        }

        val m3 = listOf(Vec2(10, 50), Vec2(50, 50), Vec2(90, 50))
        assertTrue(StrokeSmoother.isStrokeAcceptable(m3, m3, 3))
        assertTrue(StrokeSmoother.isStrokeAcceptable(m3, m3, 2))
        assertFalse(StrokeSmoother.isStrokeAcceptable(m3, m3, 0))
    }

    @Test
    fun testStrokePathParser() {
        val cmds = StrokePathParser.parseCommands(
            "M 100 200 L 300 400 Q 400 500 600 700 Z",
            CanvasSize(1024, 1024)
        )
        assertEquals(4, cmds.size)
    }

    @Test
    fun testAppUpdateService() {
        assertTrue(AppVersion("1.0.0") < AppVersion("1.0.1"))
        assertTrue(AppVersion("1.9.9") < AppVersion("1.10.0"))
        assertFalse(AppVersion("1.0") < AppVersion("1.0.0"))

        val props = PropertyConfig.parse(
            """
            # comment
            update_check_url=http://localhost:8000/version.json
            key_with_spaces =  value with spaces 
            """.trimIndent()
        )
        assertEquals("http://localhost:8000/version.json", props["update_check_url"])
        assertEquals("value with spaces", props["key_with_spaces"])

        val snake = AppUpdateInfo.decodeFromJson(
            """
            {
                "latest_version": "1.2.0",
                "min_supported_version": "1.0.1",
                "release_notes": "Bug fixes",
                "app_store_url": "https://apps.apple.com/app/id999",
                "force_update": false
            }
            """.trimIndent()
        )
        assertEquals("1.2.0", snake.latestVersion)
        assertEquals("1.0.1", snake.minSupportedVersion)

        val service = AppUpdateService(currentVersionString = "1.0.0")
        service.evaluateUpdate(
            AppUpdateInfo(
                latestVersion = "1.2.0",
                minSupportedVersion = "1.1.0",
                forceUpdate = false
            )
        )
        assertTrue(service.isForcedUpdate)
        assertFalse(service.isOptionalUpdate)

        service.evaluateUpdate(
            AppUpdateInfo(
                latestVersion = "1.2.0",
                minSupportedVersion = "1.0.0",
                forceUpdate = false
            )
        )
        assertFalse(service.isForcedUpdate)
        assertTrue(service.isOptionalUpdate)
        service.dismissOptionalNotice()
        assertFalse(service.hasUnreadUpdate)
    }

    @Test
    fun testGridCellSizeAndFontSizeClamping() {
        assertEquals(GridCellSize.MEDIUM, GridCellSize.defaultSize)
        assertEquals("kGridCellSize", GridCellSize.storageKey)
        assertEquals(listOf("Small", "Medium", "Large"), GridCellSize.entries.map { it.title })

        assertEquals(160.0, CharacterDetailConfig.clampFontSize(50.0), 0.001)
        assertEquals(520.0, CharacterDetailConfig.clampFontSize(900.0), 0.001)
        assertEquals(300.0, CharacterDetailConfig.clampFontSize(300.0), 0.001)
    }

    @Test
    fun testPracticeStorageServiceInMemory() {
        val storage = PracticeStorageService(null)
        assertEquals(0, storage.getPracticeCount("爱", "2026-10-30"))
        assertEquals(1, storage.recordPractice("爱", "2026-10-30"))
        assertEquals(2, storage.recordPractice("爱", "2026-10-30"))
        assertEquals(1, storage.recordPractice("爱", "2026-10-31"))
        assertEquals(3, storage.getTotalPracticeCount("爱"))
    }
}
