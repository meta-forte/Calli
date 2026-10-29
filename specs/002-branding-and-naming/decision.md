# Branding and Naming Strategy Decision

## Context
When launching the app without a paid user acquisition budget, organic App Store Optimization (ASO) and search discovery are paramount. The target audience comprises non-Chinese native learners, international school expat children, multi-faith families, and university aspirants preparing for HSK certification.

## Final Decisions

### 1. Selected App Name: HanziSlate
- **Brand Name:** `HanziSlate`
- **Home Screen Display Name (`CFBundleDisplayName`):** `HanziSlate` (10 characters, sleek, zero truncation on iOS and Android).
- **Bundle Identifier:** `com.ibhatech.hanzislate`
- **Rationale:** 
  - Revives the tactile "Slate" learning metaphor from the original product vision.
  - 100% unclaimed on both Apple App Store and Google Play Store (avoiding the conflict found with `Hanzi Pad: Chinese Writing` on iOS and `HanziTrace` on Android).
  - Uses the category anchor `Hanzi` to eliminate collisions with dialers, call recorders, or health/medical apps (avoiding the word "stroke").
  - Approachable, modern, secular, and universally understandable for international school families.

### 2. Company Name Placement
- The company name (`Ibhatech`) will **NOT** be included in the consumer-facing App Store Title, Subtitle, or Home Screen Display Name.
- Company identity will be established through:
  - Developer Account Name (`Developer: Ibhatech`).
  - Minimal 1-second launch screen ("HanziSlate by Ibhatech").
  - In-app "About / More by Ibhatech" cross-promotion.

### 3. App Store Metadata Configuration

- **Metadata Source File:** [Calli/Resources/AppStoreMetadata.properties](file:///Users/manas/dev/Calli/Calli/Resources/AppStoreMetadata.properties)

#### Apple App Store:
- **Title (Strictly Max 30 chars):** `HanziSlate: Practice Chinese` (26 characters)
- **Subtitle (Strictly Max 30 chars):** `Character Tracing & Listening` (29 characters)
- **Promotional Text (Max 170 chars):** `Practice Hanzi character tracing and listening. Covers official HSK 3.0 (Levels 1-9) with stroke animations, pinyin audio, and tonal listening.` (141 characters)
- **Keywords (Max 100 chars):** `chinese,hanzi,hsk,stroke,character,pinyin,trace,tracing,writing,practice,listen,listening,mandarin`

#### Google Play Store:
- **Title (Strictly Max 30 chars):** `HanziSlate: Practice Chinese` (26 characters)
- **Short Description (Strictly Max 80 chars):** `Practice Hanzi character tracing, HSK 1-9 writing, and tonal pinyin listening.` (78 characters)
