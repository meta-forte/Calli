# Feature Specification: Character Grid Font Size Slider

## 1. Feature Overview
Provide an intuitive slider control allowing users to dynamically adjust the font size of Chinese characters in the grid view between **12 pt** and **48 pt**.

## 2. iPad Usability Analysis: Why 12 pt to 48 pt is the Optimal Boundary

### The Question: Is anything above 48 pt unusable on iPad?
**Agreement: Yes, for the grid view, anything above 48 pt becomes counterproductive and unusable.**

### Usability Rationale:
1. **Grid Density & Purpose:**
   - The primary purpose of the grid screen is **scanning, browsing, and selecting** characters from the HSK syllabus.
   - At 48 pt, with comfortable cell padding and Pinyin labels, each cell requires roughly **80x90 pt** of screen space. On an iPad (e.g., 810 to 1024 pt width), this renders 8 to 10 characters per row.
   - If font sizes increase beyond 48 pt (e.g., 64 pt or 80 pt), cells expand to 130-160 pt, reducing the grid to just 3 to 4 massive cells per row. This destroys the grid's ability to provide a comprehensive overview and turns it into an awkward carousel.
2. **Separation of Concerns (Grid vs. Tracing View):**
   - When a user actually wants a large character for detailed inspection and tracing, they tap the cell, which opens the **full-screen tracing canvas** (where the character is rendered at ~300-500 pt).
   - Therefore, the grid only needs to support browsing sizes (12 pt to 48 pt).
3. **The 12 pt Lower Bound:**
   - 12 pt is the minimum legible size for complex Chinese characters with 15-25 strokes (such as 囊, 赢, 鬱) on standard retina displays without stroke blurring.

---

## 3. UI/UX Specifications

### 3.1 Slider Control Placement
- Located in the toolbar header or within a collapsible display options bar next to the HSK Level dropdown.
- Shows minimum icon (small `A` or `文`) at 12 pt and maximum icon (large `A` or `文`) at 48 pt.
- Displays current font size value in real-time (e.g., `24 pt`).

### 3.2 Technical Requirements
- **Range:** `12.0 ... 48.0` (Continuous slider with step increments of `1.0` or `2.0` pt).
- **Default Value:** `24.0 pt` (Comfortable balance on both iPhone and iPad).
- **Persistence:** Save value to `UserDefaults` under key `kGridCharacterFontSize` so user preference persists across app launches.
- **Adaptive Layout:**
  - Grid columns must automatically recalculate using `LazyVGrid` with `GridItem(.adaptive(minimum: calculatedCellWidth))` so rows reflow smoothly as the slider moves.
- **Pinyin Font Scaling:**
  - Pinyin font size should scale proportionally with character size (e.g., `fontSize * 0.45` bounded between `10 pt` and `18 pt`) to preserve visual hierarchy.
