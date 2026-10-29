# Legal, Compliance, Disclaimers, and Open-Source Attributions

## 1. Legal Analysis & Rights

### HSK Standard & Vocabulary
- **Legal Status:** The Chinese Ministry of Education / Center for Language Education and Cooperation (CLEC) publishes the HSK 3.0 standards (`《国际中文教育中文水平等级标准》`) as public educational standards. Factual character lists, grade levels, and standard definitions are non-copyrightable facts.
- **Trademark Protection:** "HSK" (Hànyǔ Shuǐpíng Kǎoshì) is a registered trademark of Chinese Testing International (CTI). Under nominative fair use, developers may use "HSK" to describe what their tool teaches (e.g., "Aligned with HSK 3.0 syllabus"), but must never claim official endorsement, official certification, or display official CTI/Hanban logos.

### MakeMeAHanzi Stroke & Dictionary Data
- **Stroke Graphics (`graphics.txt`):**
  - Source: MakeMeAHanzi (`skishore/makemeahanzi`), derived from Arphic PL KaitiM GB / PL UKai fonts.
  - License: **Arphic Public License (APL)**.
  - Commercial Use: Fully permitted for commercial and non-commercial software, provided Arphic attribution is included.
- **Dictionary & Metadata (`dictionary.txt`):**
  - Source: Derived from Unihan database and CJKlib.
  - License: **GNU Lesser General Public License v3 (LGPL-3.0)**.
  - Compliance: Data is processed at build time into static JSON (`characters.json`, `strokes.json`). Proper attribution and links to upstream source repositories fulfill standard compliance.

---

## 2. Action Items

### Action Item 1: App Store & Google Play Store Listing Copy
Add the following mandatory disclaimer to the bottom of the App Store and Google Play descriptions:

```text
Disclaimer:
HSK is a registered trademark of Chinese Testing International (CTI). This application is an independent educational study aid and is not officially affiliated with, endorsed by, or certified by CTI, Hanban, or the Center for Language Education and Cooperation (CLEC).
```

### Action Item 2: In-App "About & Legal / Acknowledgements" Screen
Create a dedicated section in the app (accessible via a Settings or Info icon) containing:
1. App version & developer info (`Ibhatech`).
2. Trademark Disclaimer.
3. Open-Source Attributions.

#### Required In-App Copy:
```text
Legal & Disclaimers:
HSK is a registered trademark of Chinese Testing International (CTI). This application is an independent study tool and is not affiliated with or endorsed by CTI or CLEC.

Open-Source Attributions:
- Chinese character stroke graphics and vector data are derived from the MakeMeAHanzi project (by skishore) and Arphic PL Fonts, released under the Arphic Public License (APL).
- Dictionary data is derived from the Unihan Database and CJKlib under the LGPL-3.0 license.
- Character lists and standard levels are aligned with the official Chinese Proficiency Grading Standards for International Chinese Language Education (HSK 3.0).
```

### Action Item 3: Add `ACKNOWLEDGEMENTS.md` to Repository
Create an `ACKNOWLEDGEMENTS.md` or `LICENSES.txt` file in the project repository root that bundles:
- Full text of the Arphic Public License (APL).
- Link to the MakeMeAHanzi repository (`https://github.com/skishore/makemeahanzi`).
- Link to the official HSK 3.0 documentation standard.
