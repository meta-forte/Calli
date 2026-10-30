package com.ibhatech.hanzislate.models

import java.text.Normalizer
import java.util.Locale

data class CharacterSection(
    val level: Int,
    val characters: List<CharacterItem>
) {
    val id: Int
        get() = level

    val title: String
        get() = CharacterItem.title(forLevel = level)
}

data class PinyinSyllable(
    val base: String,
    val tone: Int?
) {
    val uFoldedBase: String
        get() = base.replace("v", "u")

    companion object {
        fun parse(text: String): PinyinSyllable? {
            val base = StringBuilder()
            var tone: Int? = null
            var previousWasU = false
            val decomposed = Normalizer.normalize(text.lowercase(Locale.ROOT), Normalizer.Form.NFD)
            var i = 0
            while (i < decomposed.length) {
                val cp = decomposed.codePointAt(i)
                when (cp) {
                    0x0304 -> tone = 1
                    0x0301 -> tone = 2
                    0x030C -> tone = 3
                    0x0300 -> tone = 4
                    0x0308 -> {
                        if (base.isNotEmpty() && base[base.length - 1] == 'u') {
                            base.setCharAt(base.length - 1, 'v')
                        }
                    }
                    0x3A -> {
                        if (previousWasU && base.isNotEmpty()) {
                            base.setCharAt(base.length - 1, 'v')
                        } else {
                            return null
                        }
                    }
                    in 0x31..0x35 -> {
                        tone = cp - 0x30
                    }
                    in 0x61..0x7A -> {
                        base.appendCodePoint(cp)
                    }
                    else -> return null
                }
                previousWasU = (cp == 'u'.code)
                i += Character.charCount(cp)
            }
            return if (base.isEmpty()) null else PinyinSyllable(base = base.toString(), tone = tone)
        }
    }
}

object EnglishLemmatizer {
    private val irregulars: Map<String, String> = mapOf(
        "leaves" to "leaf", "sheaves" to "sheaf", "loaves" to "loaf", "halves" to "half",
        "calves" to "calf", "wolves" to "wolf", "thieves" to "thief", "shelves" to "shelf",
        "elves" to "elf", "selves" to "self", "hooves" to "hoof", "scarves" to "scarf",
        "wharves" to "wharf", "knives" to "knife", "wives" to "wife", "lives" to "life",
        "children" to "child", "men" to "man", "women" to "woman", "teeth" to "tooth",
        "feet" to "foot", "mice" to "mouse", "geese" to "goose", "lice" to "louse",
        "oxen" to "ox", "people" to "person", "brethren" to "brother", "dice" to "die",
        "lies" to "lie", "dies" to "die", "ties" to "tie", "pies" to "pie", "vies" to "vie",
        "shoes" to "shoe", "toes" to "toe", "foes" to "foe", "woes" to "woe", "hoes" to "hoe",
        "canoes" to "canoe", "axes" to "axe", "aches" to "ache",
        "ate" to "eat", "eaten" to "eat", "sang" to "sing", "sung" to "sing",
        "wrote" to "write", "written" to "write", "went" to "go", "gone" to "go",
        "saw" to "see", "seen" to "see", "took" to "take", "taken" to "take",
        "gave" to "give", "given" to "give", "spoke" to "speak", "spoken" to "speak",
        "broke" to "break", "broken" to "break", "drove" to "drive", "driven" to "drive",
        "flew" to "fly", "flown" to "fly", "grew" to "grow", "grown" to "grow",
        "knew" to "know", "known" to "know", "threw" to "throw", "thrown" to "throw",
        "wore" to "wear", "worn" to "wear", "tore" to "tear", "torn" to "tear",
        "swore" to "swear", "sworn" to "swear", "bore" to "bear", "born" to "bear",
        "borne" to "bear", "chose" to "choose", "chosen" to "choose",
        "froze" to "freeze", "frozen" to "freeze", "stole" to "steal", "stolen" to "steal",
        "woke" to "wake", "woken" to "wake", "fell" to "fall", "fallen" to "fall",
        "held" to "hold", "stood" to "stand", "understood" to "understand",
        "lost" to "lose", "built" to "build", "sent" to "send", "spent" to "spend",
        "lent" to "lend", "bent" to "bend", "slept" to "sleep", "kept" to "keep",
        "wept" to "weep", "swept" to "sweep", "felt" to "feel", "meant" to "mean",
        "dreamt" to "dream", "learnt" to "learn", "burnt" to "burn",
        "bought" to "buy", "brought" to "bring", "caught" to "catch", "taught" to "teach",
        "thought" to "think", "fought" to "fight", "sought" to "seek",
        "sold" to "sell", "told" to "tell", "paid" to "pay", "said" to "say",
        "laid" to "lay", "made" to "make", "had" to "have", "has" to "have",
        "did" to "do", "done" to "do", "does" to "do",
        "was" to "be", "were" to "be", "been" to "be", "am" to "be", "are" to "be",
        "ran" to "run", "began" to "begin", "begun" to "begin",
        "drank" to "drink", "drunk" to "drink", "rang" to "ring", "rung" to "ring",
        "sank" to "sink", "sunk" to "sink", "swam" to "swim", "swum" to "swim",
        "won" to "win", "sat" to "sit", "met" to "meet", "led" to "lead",
        "fed" to "feed", "bled" to "bleed", "fled" to "flee", "shot" to "shoot",
        "dug" to "dig", "hung" to "hang", "stung" to "sting", "swung" to "swing",
        "clung" to "cling", "flung" to "fling", "spun" to "spin", "struck" to "strike",
        "stuck" to "stick", "shook" to "shake", "shaken" to "shake",
        "forgave" to "forgive", "forgiven" to "forgive", "forgot" to "forget", "forgotten" to "forget",
        "hid" to "hide", "hidden" to "hide", "bit" to "bite", "bitten" to "bite",
        "rode" to "ride", "ridden" to "ride", "rose" to "rise", "risen" to "rise",
        "wove" to "weave", "woven" to "weave", "blew" to "blow", "blown" to "blow",
        "drew" to "draw", "drawn" to "draw", "slew" to "slay", "slain" to "slay"
    )

    private val invariantS: Set<String> = setOf(
        "his", "this", "yes", "bus", "gas", "plus", "thus", "us", "as", "is",
        "always", "sometimes", "towards", "forwards", "backwards", "upwards",
        "downwards", "outwards", "inwards", "afterwards", "besides", "news",
        "series", "species", "means", "lens", "chaos", "cosmos", "status",
        "virus", "focus", "campus", "circus", "bonus", "minus", "genius",
        "radius", "census", "chorus", "lotus", "mucus", "citrus", "cactus",
        "fungus", "atlas", "canvas", "compass", "christmas", "bias", "alias",
        "clothes", "goods", "stairs", "outdoors", "indoors", "customs"
    )

    fun lemma(of: String): String {
        val lower = of.lowercase(Locale.ROOT)
        irregulars[lower]?.let { return it }
        if (lower.length < 3 || invariantS.contains(lower)) {
            return lower
        }
        if (lower.endsWith("ies") && lower.length >= 4) {
            return lower.dropLast(3) + "y"
        }
        if (lower.endsWith("ves") && lower.length >= 5) {
            return lower.dropLast(3) + "f"
        }
        if (lower.endsWith("ches") || lower.endsWith("shes") || lower.endsWith("xes")
            || lower.endsWith("sses") || lower.endsWith("zes") || lower.endsWith("oes")
        ) {
            return lower.dropLast(2)
        }
        if (lower.endsWith("s") && !lower.endsWith("ss") && !lower.endsWith("us") && !lower.endsWith("is")) {
            return lower.dropLast(1)
        }
        return lower
    }
}

data class CharacterSearchResult(
    val sections: List<CharacterSection>,
    val matchedMeanings: Map<Int, String>
)

class CharacterSearchIndex(characters: List<CharacterItem>) {
    enum class MatchRank {
        HANZI,
        PINYIN_EXACT,
        MEANING_WORD,
        PINYIN_PREFIX,
        MEANING_PREFIX
    }

    private data class WordToken(
        val raw: String,
        val lemma: String
    )

    private data class GlossClause(
        val display: String,
        val tokens: List<WordToken>
    )

    private data class Entry(
        val item: CharacterItem,
        val syllables: List<PinyinSyllable>,
        val meaningTokens: List<WordToken>,
        val clauses: List<GlossClause>,
        val primaryGloss: String
    )

    private data class Query(
        val hanzi: Set<String>,
        val syllables: List<PinyinSyllable>,
        val meaningTokens: List<WordToken>,
        val allowsPinyinPrefix: Boolean
    )

    private val entries: List<Entry>
    private val validPinyinBases: Set<String>
    private val knownEnglishLemmas: Set<String>

    init {
        val pinyinBases = mutableSetOf<String>()
        val englishLemmas = mutableSetOf<String>()
        val builtEntries = ArrayList<Entry>(characters.size)

        for (item in characters) {
            val parsedSyllables = readings(of = item.pinyin).map { syllable ->
                PinyinSyllable(base = syllable.base, tone = syllable.tone ?: 5)
            }
            for (syllable in parsedSyllables) {
                pinyinBases.add(syllable.base)
                pinyinBases.add(syllable.uFoldedBase)
            }

            val tokens = tokenize(item.meaning)
            for (token in tokens) {
                englishLemmas.add(token.raw)
                englishLemmas.add(token.lemma)
            }

            val clauses = parseClauses(item.meaning)
            val primary = clauses.firstOrNull()?.display ?: item.meaning

            builtEntries.add(
                Entry(
                    item = item,
                    syllables = parsedSyllables,
                    meaningTokens = tokens,
                    clauses = clauses,
                    primaryGloss = primary
                )
            )
        }

        this.entries = builtEntries
        this.validPinyinBases = pinyinBases
        this.knownEnglishLemmas = englishLemmas
    }

    fun search(text: String): List<CharacterSection> {
        return searchWithContext(text).sections
    }

    fun searchWithContext(text: String): CharacterSearchResult {
        val query = parse(text) ?: return CharacterSearchResult(emptyList(), emptyMap())

        data class RankedItem(val rank: MatchRank, val order: Int, val item: CharacterItem)

        val matchesByLevel = mutableMapOf<Int, MutableList<RankedItem>>()
        val matchedMeanings = mutableMapOf<Int, String>()

        for ((order, entry) in entries.withIndex()) {
            val matchResult = match(entry = entry, query = query)
            if (matchResult != null) {
                val (rank, gloss) = matchResult
                matchesByLevel.getOrPut(entry.item.level) { mutableListOf() }
                    .add(RankedItem(rank, order, entry.item))
                if (gloss.isNotEmpty()) {
                    matchedMeanings[entry.item.id] = gloss
                }
            }
        }

        val sortedLevels = matchesByLevel.keys.sortedWith { lhs, rhs ->
            when {
                lhs == rhs -> 0
                CharacterItem.levelPrecedes(lhs, rhs) -> -1
                else -> 1
            }
        }

        val sections = sortedLevels.map { level ->
            val ordered = matchesByLevel[level].orEmpty()
                .sortedWith(compareBy<RankedItem> { it.rank.ordinal }.thenBy { it.order })
                .map { it.item }
            CharacterSection(level = level, characters = ordered)
        }

        return CharacterSearchResult(sections = sections, matchedMeanings = matchedMeanings)
    }

    private fun parse(text: String): Query? {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return null

        val hanziSet = extractHanziCharacters(trimmed)
        if (hanziSet.isNotEmpty()) {
            return Query(
                hanzi = hanziSet,
                syllables = emptyList(),
                meaningTokens = emptyList(),
                allowsPinyinPrefix = false
            )
        }

        val rawTokens = splitRawTokens(trimmed)
        val syllables = rawTokens.mapNotNull { PinyinSyllable.parse(it) }
        val isExplicitPinyin = syllables.any { it.tone != null } ||
            rawTokens.any { it.contains("ü") || it.contains(":") }
        val meaningTokens = if (isExplicitPinyin) emptyList() else tokenize(trimmed)

        if (syllables.isEmpty() && meaningTokens.isEmpty()) return null

        val isSingleKnownEnglishOnlyWord: Boolean = run {
            if (syllables.size != 1 || meaningTokens.size != 1) return@run false
            val syl = syllables.first()
            if (syl.tone != null) return@run false
            val isExactPinyin = validPinyinBases.contains(syl.base) || validPinyinBases.contains(syl.uFoldedBase)
            val isExactEnglish = knownEnglishLemmas.contains(meaningTokens[0].raw) ||
                knownEnglishLemmas.contains(meaningTokens[0].lemma)
            !isExactPinyin && isExactEnglish
        }

        return Query(
            hanzi = emptySet(),
            syllables = syllables,
            meaningTokens = meaningTokens,
            allowsPinyinPrefix = !isSingleKnownEnglishOnlyWord
        )
    }

    private fun match(entry: Entry, query: Query): Pair<MatchRank, String>? {
        if (query.hanzi.isNotEmpty()) {
            if (!query.hanzi.contains(entry.item.hanzi)) return null
            return MatchRank.HANZI to entry.primaryGloss
        }

        val pRank = pinyinRank(entry = entry, query = query)
        val mMatch = meaningMatch(entry = entry, query = query)

        return when {
            pRank != null && mMatch != null -> {
                if (pRank.ordinal <= mMatch.first.ordinal) {
                    pRank to entry.primaryGloss
                } else {
                    mMatch
                }
            }
            pRank != null -> pRank to entry.primaryGloss
            mMatch != null -> mMatch
            else -> null
        }
    }

    companion object {
        const val minMeaningPrefixLength = 4

        private val standaloneOnlyWords: Set<String> = setOf(
            "for", "to", "in", "on", "at", "by", "of", "with", "from", "as",
            "into", "onto", "upon", "over", "under", "about", "after", "before",
            "between", "among", "through", "during", "without", "within", "against",
            "towards", "toward", "around", "across", "along", "behind", "below",
            "beside", "beyond", "near", "off", "out", "up", "down",
            "and", "or", "but", "if", "so", "yet", "nor",
            "a", "an", "the"
        )

        private fun pinyinRank(entry: Entry, query: Query): MatchRank? {
            var best: MatchRank? = null
            for ((index, wanted) in query.syllables.withIndex()) {
                val allowsPrefix = query.allowsPinyinPrefix && wanted.tone == null && index == query.syllables.size - 1
                for (reading in entry.syllables) {
                    val bases = listOf(reading.base, reading.uFoldedBase)
                    val toneMatches = wanted.tone?.let { it == reading.tone } ?: true
                    if (toneMatches && bases.contains(wanted.base)) {
                        return MatchRank.PINYIN_EXACT
                    }
                    if (allowsPrefix && bases.any { it.startsWith(wanted.base) }) {
                        best = MatchRank.PINYIN_PREFIX
                    }
                }
            }
            return best
        }

        private fun meaningMatch(entry: Entry, query: Query): Pair<MatchRank, String>? {
            val wanted = query.meaningTokens
            if (wanted.isEmpty()) return null

            var bestClauseMatch: Pair<MatchRank, String>? = null
            for (clause in entry.clauses) {
                val rank = matchTokens(words = clause.tokens, wanted = wanted)
                if (rank != null) {
                    if (bestClauseMatch == null || rank.ordinal < bestClauseMatch.first.ordinal) {
                        bestClauseMatch = rank to clause.display
                    }
                    if (rank == MatchRank.MEANING_WORD) {
                        return bestClauseMatch
                    }
                }
            }

            if (bestClauseMatch != null) {
                return bestClauseMatch
            }

            if (wanted.size > 1) {
                val rank = matchTokens(words = entry.meaningTokens, wanted = wanted)
                if (rank != null) {
                    return rank to entry.primaryGloss
                }
            }
            return null
        }

        private fun matchTokens(words: List<WordToken>, wanted: List<WordToken>): MatchRank? {
            val last = wanted.lastOrNull() ?: return null
            if (words.size < wanted.size) return null

            if (wanted.size == 1 && standaloneOnlyWords.contains(last.raw)) {
                if (words.size != 1) return null
                val candidate = words[0]
                if (candidate.raw == last.raw || candidate.lemma == last.lemma) {
                    return MatchRank.MEANING_WORD
                }
                return null
            }

            val allowsPrefix = last.raw.length >= minMeaningPrefixLength
            var best: MatchRank? = null

            for (start in 0..(words.size - wanted.size)) {
                var leadingMatches = true
                for (i in 0 until (wanted.size - 1)) {
                    val candidate = words[start + i]
                    val queryToken = wanted[i]
                    if (candidate.raw != queryToken.raw && candidate.lemma != queryToken.lemma) {
                        leadingMatches = false
                        break
                    }
                }
                if (!leadingMatches) continue

                val candidate = words[start + wanted.size - 1]
                if (candidate.raw == last.raw || candidate.lemma == last.lemma) {
                    return MatchRank.MEANING_WORD
                }
                if (allowsPrefix && candidate.raw.startsWith(last.raw)) {
                    best = MatchRank.MEANING_PREFIX
                }
            }
            return best
        }

        private fun readings(of: String): List<PinyinSyllable> {
            return of.split(Regex("""[,;/\s]+"""))
                .filter { it.isNotEmpty() }
                .mapNotNull { PinyinSyllable.parse(it) }
        }

        private fun stripDiacriticsAndLower(text: String): String {
            val nfd = Normalizer.normalize(text.lowercase(Locale.ROOT), Normalizer.Form.NFD)
            val sb = StringBuilder(nfd.length)
            var i = 0
            while (i < nfd.length) {
                val cp = nfd.codePointAt(i)
                val type = Character.getType(cp)
                if (type != Character.NON_SPACING_MARK.toInt() &&
                    type != Character.COMBINING_SPACING_MARK.toInt() &&
                    type != Character.ENCLOSING_MARK.toInt()
                ) {
                    sb.appendCodePoint(cp)
                }
                i += Character.charCount(cp)
            }
            return sb.toString()
        }

        private fun tokenize(text: String): List<WordToken> {
            val folded = stripDiacriticsAndLower(text)
            val result = mutableListOf<WordToken>()
            val current = StringBuilder()
            var i = 0
            while (i < folded.length) {
                val cp = folded.codePointAt(i)
                if (Character.isLetter(cp)) {
                    current.appendCodePoint(cp)
                } else if (current.isNotEmpty()) {
                    val raw = current.toString()
                    result.add(WordToken(raw = raw, lemma = EnglishLemmatizer.lemma(raw)))
                    current.setLength(0)
                }
                i += Character.charCount(cp)
            }
            if (current.isNotEmpty()) {
                val raw = current.toString()
                result.add(WordToken(raw = raw, lemma = EnglishLemmatizer.lemma(raw)))
            }
            return result
        }

        private fun parseClauses(meaning: String): List<GlossClause> {
            return meaning.split(';', ',')
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .mapNotNull { segment ->
                    val tokens = tokenize(segment)
                    if (tokens.isEmpty()) null else GlossClause(display = segment, tokens = tokens)
                }
        }

        private fun splitRawTokens(text: String): List<String> {
            val tokens = mutableListOf<String>()
            val current = StringBuilder()
            var i = 0
            while (i < text.length) {
                val cp = text.codePointAt(i)
                if (Character.isLetterOrDigit(cp) || cp == ':'.code ||
                    Character.getType(cp) == Character.NON_SPACING_MARK.toInt()
                ) {
                    current.appendCodePoint(cp)
                } else if (current.isNotEmpty()) {
                    tokens.add(current.toString())
                    current.setLength(0)
                }
                i += Character.charCount(cp)
            }
            if (current.isNotEmpty()) {
                tokens.add(current.toString())
            }
            return tokens
        }

        private fun extractHanziCharacters(text: String): Set<String> {
            val set = mutableSetOf<String>()
            var i = 0
            while (i < text.length) {
                val cp = text.codePointAt(i)
                if (isHanziCodePoint(cp)) {
                    set.add(String(Character.toChars(cp)))
                }
                i += Character.charCount(cp)
            }
            return set
        }

        private fun isHanziCodePoint(cp: Int): Boolean {
            return cp in 0x2E80..0x2FDF ||
                cp == 0x3005 ||
                cp == 0x3007 ||
                cp in 0x3021..0x3029 ||
                cp in 0x3400..0x4DBF ||
                cp in 0x4E00..0x9FFF ||
                cp in 0xF900..0xFAFF ||
                cp in 0x20000..0x323AF
        }
    }
}
