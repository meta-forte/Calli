# Product Strategy: Market Positioning and Growth Roadmap

## 1. Target Audience and Market Positioning

### Target Audience Realism
- The app is **not** a general-purpose, conversational language learning app for casual tourists or travelers. Casual learners prioritize conversational phrases, listening comprehension, and Pinyin, not memorizing and drawing hundreds of Chinese character strokes.
- The actual core target audience consists of:
  1. **HSK Exam Candidates (Levels 1 to 9):** Students who must write and recognize characters to pass official tests (especially HSK 3 and above).
  2. **University & School Students:** Learners taking formal Chinese courses requiring character handwriting assignments.
  3. **Dedicated Hanzi Enthusiasts:** Learners specifically fascinated by Chinese character stroke order, etymology, and calligraphy.

### Market Positioning: The Focused Companion App
- The app should be positioned as a **dedicated Hanzi stroke & handwriting companion**, not an all-in-one conversational app.
- Competitor differentiation:
  - **Skritter:** Market leader for handwriting, but charges high subscription rates ($14.99/mo or $99/yr).
  - **Pleco:** Dominant dictionary, but stroke order is a static animation or paid add-on, not an interactive finger-tracing canvas.
  - **Generic Stroke Apps:** Frequently cluttered with ads, outdated UI, or stuck on obsolete HSK 2.0 standards.
  - **This App:** Native SwiftUI, distraction-free, zero ad clutter, fully aligned with the **HSK 3.0 (Levels 1-9)** standard.

## 2. Release Strategy (MVP First)

- **Release As-Is:** Ship the current MVP focusing on single-character stroke tracing, Pinyin audio, and HSK 1-9 level filtering.
- **Benefits:**
  - Starts building App Store index history and domain authority early.
  - Validates gesture responsiveness, stroke tolerance, and user retention.
  - Avoids feature bloat before getting real user feedback.

## 3. Product Evolution Roadmap

Using the datasets already present in `docs/`:

1. **v1.0 (Current MVP):**
   - HSK 1-9 character grid.
   - Interactive stroke tracing with directional guidance.
   - Pinyin audio playback.
2. **v1.5 (Active Recall / Quiz Mode):**
   - Spaced Repetition System (SRS).
   - Freehand test mode where stroke hints disappear and users write from memory.
3. **v2.0 (Vocabulary & Multi-Character Words):**
   - Utilize `docs/hsk-3.0-words-all.csv`.
   - Practice multi-character words (e.g., 爸爸, 超市, 中国).
4. **v3.0 (Grammar & Sentence Construction):**
   - Utilize `docs/hsk-3.0-grammar-all.csv`.
   - Grammar explanations, patterns, and interactive sentence building.
