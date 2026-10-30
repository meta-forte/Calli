import Foundation

struct CharacterSection: Identifiable, Equatable {
    let level: Int
    let characters: [CharacterItem]

    var id: Int { level }
    var title: String { CharacterItem.title(forLevel: level) }
}

struct PinyinSyllable: Equatable {
    let base: String
    let tone: Int?

    var uFoldedBase: String { base.replacingOccurrences(of: "v", with: "u") }

    static func parse(_ text: String) -> PinyinSyllable? {
        var base = ""
        var tone: Int?
        var previousWasU = false
        for scalar in text.lowercased().decomposedStringWithCanonicalMapping.unicodeScalars {
            switch scalar.value {
            case 0x0304: tone = 1
            case 0x0301: tone = 2
            case 0x030C: tone = 3
            case 0x0300: tone = 4
            case 0x0308:
                if base.hasSuffix("u") {
                    base.removeLast()
                    base.append("v")
                }
            case 0x3A where previousWasU:
                base.removeLast()
                base.append("v")
            case 0x31...0x35:
                tone = Int(scalar.value - 0x30)
            case 0x61...0x7A:
                base.unicodeScalars.append(scalar)
            default:
                return nil
            }
            previousWasU = scalar == "u"
        }
        return base.isEmpty ? nil : PinyinSyllable(base: base, tone: tone)
    }
}

enum EnglishLemmatizer {
    private static let irregulars: [String: String] = [
        "leaves": "leaf", "sheaves": "sheaf", "loaves": "loaf", "halves": "half",
        "calves": "calf", "wolves": "wolf", "thieves": "thief", "shelves": "shelf",
        "elves": "elf", "selves": "self", "hooves": "hoof", "scarves": "scarf",
        "wharves": "wharf", "knives": "knife", "wives": "wife", "lives": "life",
        "children": "child", "men": "man", "women": "woman", "teeth": "tooth",
        "feet": "foot", "mice": "mouse", "geese": "goose", "lice": "louse",
        "oxen": "ox", "people": "person", "brethren": "brother", "dice": "die",
        "lies": "lie", "dies": "die", "ties": "tie", "pies": "pie", "vies": "vie",
        "shoes": "shoe", "toes": "toe", "foes": "foe", "woes": "woe", "hoes": "hoe",
        "canoes": "canoe", "axes": "axe", "aches": "ache",
        "ate": "eat", "eaten": "eat", "sang": "sing", "sung": "sing",
        "wrote": "write", "written": "write", "went": "go", "gone": "go",
        "saw": "see", "seen": "see", "took": "take", "taken": "take",
        "gave": "give", "given": "give", "spoke": "speak", "spoken": "speak",
        "broke": "break", "broken": "break", "drove": "drive", "driven": "drive",
        "flew": "fly", "flown": "fly", "grew": "grow", "grown": "grow",
        "knew": "know", "known": "know", "threw": "throw", "thrown": "throw",
        "wore": "wear", "worn": "wear", "tore": "tear", "torn": "tear",
        "swore": "swear", "sworn": "swear", "bore": "bear", "born": "bear",
        "borne": "bear", "chose": "choose", "chosen": "choose",
        "froze": "freeze", "frozen": "freeze", "stole": "steal", "stolen": "steal",
        "woke": "wake", "woken": "wake", "fell": "fall", "fallen": "fall",
        "held": "hold", "stood": "stand", "understood": "understand",
        "lost": "lose", "built": "build", "sent": "send", "spent": "spend",
        "lent": "lend", "bent": "bend", "slept": "sleep", "kept": "keep",
        "wept": "weep", "swept": "sweep", "felt": "feel", "meant": "mean",
        "dreamt": "dream", "learnt": "learn", "burnt": "burn",
        "bought": "buy", "brought": "bring", "caught": "catch", "taught": "teach",
        "thought": "think", "fought": "fight", "sought": "seek",
        "sold": "sell", "told": "tell", "paid": "pay", "said": "say",
        "laid": "lay", "made": "make", "had": "have", "has": "have",
        "did": "do", "done": "do", "does": "do",
        "was": "be", "were": "be", "been": "be", "am": "be", "are": "be",
        "ran": "run", "began": "begin", "begun": "begin",
        "drank": "drink", "drunk": "drink", "rang": "ring", "rung": "ring",
        "sank": "sink", "sunk": "sink", "swam": "swim", "swum": "swim",
        "won": "win", "sat": "sit", "met": "meet", "led": "lead",
        "fed": "feed", "bled": "bleed", "fled": "flee", "shot": "shoot",
        "dug": "dig", "hung": "hang", "stung": "sting", "swung": "swing",
        "clung": "cling", "flung": "fling", "spun": "spin", "struck": "strike",
        "stuck": "stick", "shook": "shake", "shaken": "shake",
        "forgave": "forgive", "forgiven": "forgive", "forgot": "forget", "forgotten": "forget",
        "hid": "hide", "hidden": "hide", "bit": "bite", "bitten": "bite",
        "rode": "ride", "ridden": "ride", "rose": "rise", "risen": "rise",
        "wove": "weave", "woven": "weave", "blew": "blow", "blown": "blow",
        "drew": "draw", "drawn": "draw", "slew": "slay", "slain": "slay"
    ]

    private static let invariantS: Set<String> = [
        "his", "this", "yes", "bus", "gas", "plus", "thus", "us", "as", "is",
        "always", "sometimes", "towards", "forwards", "backwards", "upwards",
        "downwards", "outwards", "inwards", "afterwards", "besides", "news",
        "series", "species", "means", "lens", "chaos", "cosmos", "status",
        "virus", "focus", "campus", "circus", "bonus", "minus", "genius",
        "radius", "census", "chorus", "lotus", "mucus", "citrus", "cactus",
        "fungus", "atlas", "canvas", "compass", "christmas", "bias", "alias",
        "clothes", "goods", "stairs", "outdoors", "indoors", "customs"
    ]

    static func lemma(of word: String) -> String {
        let lower = word.lowercased()
        if let mapped = irregulars[lower] {
            return mapped
        }
        guard lower.count >= 3, !invariantS.contains(lower) else {
            return lower
        }
        if lower.hasSuffix("ies") && lower.count >= 4 {
            return String(lower.dropLast(3)) + "y"
        }
        if lower.hasSuffix("ves") && lower.count >= 5 {
            return String(lower.dropLast(3)) + "f"
        }
        if lower.hasSuffix("ches") || lower.hasSuffix("shes") || lower.hasSuffix("xes")
            || lower.hasSuffix("sses") || lower.hasSuffix("zes") || lower.hasSuffix("oes") {
            return String(lower.dropLast(2))
        }
        if lower.hasSuffix("s") && !lower.hasSuffix("ss") && !lower.hasSuffix("us") && !lower.hasSuffix("is") {
            return String(lower.dropLast())
        }
        return lower
    }
}

struct CharacterSearchResult: Equatable {
    let sections: [CharacterSection]
    let matchedMeanings: [Int: String]
}

struct CharacterSearchIndex {
    static let minMeaningPrefixLength = 4

    private static let standaloneOnlyWords: Set<String> = [
        "for", "to", "in", "on", "at", "by", "of", "with", "from", "as",
        "into", "onto", "upon", "over", "under", "about", "after", "before",
        "between", "among", "through", "during", "without", "within", "against",
        "towards", "toward", "around", "across", "along", "behind", "below",
        "beside", "beyond", "near", "off", "out", "up", "down",
        "and", "or", "but", "if", "so", "yet", "nor",
        "a", "an", "the"
    ]

    enum MatchRank: Int, Comparable {
        case hanzi
        case pinyinExact
        case meaningWord
        case pinyinPrefix
        case meaningPrefix

        static func < (lhs: MatchRank, rhs: MatchRank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private struct WordToken: Equatable {
        let raw: String
        let lemma: String
    }

    private struct GlossClause {
        let display: String
        let tokens: [WordToken]
    }

    private struct Entry {
        let item: CharacterItem
        let syllables: [PinyinSyllable]
        let meaningTokens: [WordToken]
        let clauses: [GlossClause]
        let primaryGloss: String
    }

    private struct Query {
        let hanzi: Set<String>
        let syllables: [PinyinSyllable]
        let meaningTokens: [WordToken]
        let allowsPinyinPrefix: Bool
    }

    private let entries: [Entry]
    private let validPinyinBases: Set<String>
    private let knownEnglishLemmas: Set<String>

    init(characters: [CharacterItem]) {
        var pinyinBases = Set<String>()
        var englishLemmas = Set<String>()
        var builtEntries: [Entry] = []
        builtEntries.reserveCapacity(characters.count)

        for item in characters {
            let parsedSyllables = Self.readings(of: item.pinyin).map { syllable in
                PinyinSyllable(base: syllable.base, tone: syllable.tone ?? 5)
            }
            for syllable in parsedSyllables {
                pinyinBases.insert(syllable.base)
                pinyinBases.insert(syllable.uFoldedBase)
            }

            let tokens = Self.tokenize(item.meaning)
            for token in tokens {
                englishLemmas.insert(token.raw)
                englishLemmas.insert(token.lemma)
            }

            let clauses = Self.parseClauses(in: item.meaning)
            let primary = clauses.first?.display ?? item.meaning

            builtEntries.append(
                Entry(
                    item: item,
                    syllables: parsedSyllables,
                    meaningTokens: tokens,
                    clauses: clauses,
                    primaryGloss: primary
                )
            )
        }

        self.entries = builtEntries
        self.validPinyinBases = pinyinBases
        self.knownEnglishLemmas = englishLemmas
    }

    func search(_ text: String) -> [CharacterSection] {
        searchWithContext(text).sections
    }

    func searchWithContext(_ text: String) -> CharacterSearchResult {
        guard let query = parse(text) else {
            return CharacterSearchResult(sections: [], matchedMeanings: [:])
        }

        var matchesByLevel: [Int: [(rank: MatchRank, order: Int, item: CharacterItem)]] = [:]
        var matchedMeanings: [Int: String] = [:]

        for (order, entry) in entries.enumerated() {
            if let (rank, gloss) = match(entry: entry, for: query) {
                matchesByLevel[entry.item.level, default: []].append((rank, order, entry.item))
                if !gloss.isEmpty {
                    matchedMeanings[entry.item.id] = gloss
                }
            }
        }

        let sections = matchesByLevel.keys
            .sorted(by: CharacterItem.levelPrecedes)
            .map { level in
                let ordered = matchesByLevel[level, default: []]
                    .sorted { ($0.rank, $0.order) < ($1.rank, $1.order) }
                    .map(\.item)
                return CharacterSection(level: level, characters: ordered)
            }

        return CharacterSearchResult(sections: sections, matchedMeanings: matchedMeanings)
    }

    private func parse(_ text: String) -> Query? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let hanzi = Set(trimmed.filter(\.isHanzi).map(String.init))
        if !hanzi.isEmpty {
            return Query(hanzi: hanzi, syllables: [], meaningTokens: [], allowsPinyinPrefix: false)
        }

        let rawTokens = trimmed.split { !$0.isLetter && !$0.isNumber && $0 != ":" }.map(String.init)
        let syllables = rawTokens.compactMap(PinyinSyllable.parse)
        let isExplicitPinyin = syllables.contains { $0.tone != nil } || rawTokens.contains { $0.contains("ü") || $0.contains(":") }
        let meaningTokens = isExplicitPinyin ? [] : Self.tokenize(trimmed)

        guard !syllables.isEmpty || !meaningTokens.isEmpty else { return nil }

        let isSingleKnownEnglishOnlyWord: Bool = {
            guard syllables.count == 1, meaningTokens.count == 1, let syl = syllables.first, syl.tone == nil else {
                return false
            }
            let isExactPinyin = validPinyinBases.contains(syl.base) || validPinyinBases.contains(syl.uFoldedBase)
            let isExactEnglish = knownEnglishLemmas.contains(meaningTokens[0].raw) || knownEnglishLemmas.contains(meaningTokens[0].lemma)
            return !isExactPinyin && isExactEnglish
        }()

        return Query(
            hanzi: [],
            syllables: syllables,
            meaningTokens: meaningTokens,
            allowsPinyinPrefix: !isSingleKnownEnglishOnlyWord
        )
    }

    private func match(entry: Entry, for query: Query) -> (MatchRank, String)? {
        if !query.hanzi.isEmpty {
            guard query.hanzi.contains(entry.item.hanzi) else { return nil }
            return (.hanzi, entry.primaryGloss)
        }

        let pRank = Self.pinyinRank(of: entry, for: query)
        let mMatch = Self.meaningMatch(of: entry, for: query)

        switch (pRank, mMatch) {
        case let (p?, m?):
            if p <= m.rank {
                return (p, entry.primaryGloss)
            } else {
                return m
            }
        case let (p?, nil):
            return (p, entry.primaryGloss)
        case let (nil, m?):
            return m
        case (nil, nil):
            return nil
        }
    }

    private static func pinyinRank(of entry: Entry, for query: Query) -> MatchRank? {
        var best: MatchRank?
        for (index, wanted) in query.syllables.enumerated() {
            let allowsPrefix = query.allowsPinyinPrefix && wanted.tone == nil && index == query.syllables.count - 1
            for reading in entry.syllables {
                let bases = [reading.base, reading.uFoldedBase]
                let toneMatches = wanted.tone.map { $0 == reading.tone } ?? true
                if toneMatches && bases.contains(wanted.base) {
                    return .pinyinExact
                }
                if allowsPrefix && bases.contains(where: { $0.hasPrefix(wanted.base) }) {
                    best = .pinyinPrefix
                }
            }
        }
        return best
    }

    private static func meaningMatch(of entry: Entry, for query: Query) -> (rank: MatchRank, gloss: String)? {
        let wanted = query.meaningTokens
        guard !wanted.isEmpty else { return nil }

        var bestClauseMatch: (rank: MatchRank, gloss: String)?
        for clause in entry.clauses {
            if let rank = matchTokens(in: clause.tokens, wanted: wanted) {
                if bestClauseMatch == nil || rank < bestClauseMatch!.rank {
                    bestClauseMatch = (rank, clause.display)
                }
                if rank == .meaningWord {
                    return bestClauseMatch
                }
            }
        }

        if let bestClauseMatch {
            return bestClauseMatch
        }

        if wanted.count > 1, let rank = matchTokens(in: entry.meaningTokens, wanted: wanted) {
            return (rank, entry.primaryGloss)
        }
        return nil
    }

    private static func matchTokens(in words: [WordToken], wanted: [WordToken]) -> MatchRank? {
        guard let last = wanted.last, words.count >= wanted.count else { return nil }
        if wanted.count == 1 && standaloneOnlyWords.contains(last.raw) {
            guard words.count == 1 else { return nil }
            let candidate = words[0]
            if candidate.raw == last.raw || candidate.lemma == last.lemma {
                return .meaningWord
            }
            return nil
        }

        let allowsPrefix = last.raw.count >= minMeaningPrefixLength

        var best: MatchRank?
        for start in 0...(words.count - wanted.count) {
            let leadingMatches = zip(words[start...], wanted.dropLast()).allSatisfy { candidate, queryToken in
                candidate.raw == queryToken.raw || candidate.lemma == queryToken.lemma
            }
            guard leadingMatches else { continue }

            let candidate = words[start + wanted.count - 1]
            if candidate.raw == last.raw || candidate.lemma == last.lemma {
                return .meaningWord
            }
            if allowsPrefix && candidate.raw.hasPrefix(last.raw) {
                best = .meaningPrefix
            }
        }
        return best
    }

    private static func readings(of pinyin: String) -> [PinyinSyllable] {
        pinyin
            .split { $0 == "," || $0 == ";" || $0 == "/" || $0.isWhitespace }
            .compactMap { PinyinSyllable.parse(String($0)) }
    }

    private static func tokenize(_ text: String) -> [WordToken] {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split { !$0.isLetter }
            .map { substring in
                let raw = String(substring)
                return WordToken(raw: raw, lemma: EnglishLemmatizer.lemma(of: raw))
            }
    }

    private static func parseClauses(in meaning: String) -> [GlossClause] {
        let rawSegments = meaning
            .split { $0 == ";" || $0 == "," }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return rawSegments.compactMap { segment in
            let tokens = tokenize(segment)
            guard !tokens.isEmpty else { return nil }
            return GlossClause(display: segment, tokens: tokens)
        }
    }
}

private extension Character {
    var isHanzi: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x2E80...0x2FDF, 0x3005, 0x3007, 0x3021...0x3029, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF, 0x20000...0x323AF:
                return true
            default:
                return false
            }
        }
    }
}
