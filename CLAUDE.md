# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS Bible Widget application that displays daily Bible verses in 9 languages. The project consists of:
- Main iOS app ([Bible Widget/](Bible Widget/)) - Displays today's verse with language selection
- Widget extension ([bibleWidget/](bibleWidget/)) - Provides home screen and lock screen widgets
- Bible verse data ([Bible Widget/Resources/Bibles/](Bible Widget/Resources/Bibles/)) - Full Bible translations in 9 languages
- Curated references ([curated_references.json](Bible Widget/Resources/curated_references.json)) - 590 hand-selected verse references

**Bundle ID**: `com.taehun.Bible-Widget`
**Widget Extension ID**: `com.taehun.Bible-Widget.bibleWidget`
**Build**: 3

## ⚖️ CRITICAL: Public Domain Requirement

**This app is intended for commercial use (paid app). ALL Bible translations MUST be in the PUBLIC DOMAIN.**

- ✅ **ALLOWED**: Translations with NO copyright restrictions (public domain, freely reproducible for commercial use)
- ❌ **FORBIDDEN**: Any copyrighted translations requiring licenses, permissions, or royalties
- **Current public domain translations**:
  - Korean: 개역한글
  - English: King James Version (KJV)
  - Spanish: Reina-Valera 1909
  - Portuguese: Bíblia Portuguesa Mundial
  - French: Louis Segond 1910
  - German: Luther 1912
  - Russian: Russian Synodal
  - Chinese (Simplified/Traditional): 和合本

**When adding new translations**: ALWAYS verify the translation is 100% public domain and freely usable for commercial purposes. Do NOT add any translation without explicit confirmation of its public domain status.

## Building and Running

This is an Xcode project. Build and run using:
- Open `Bible Widget.xcodeproj` in Xcode
- Select target: "Bible Widget" for main app, "bibleWidgetExtension" for widget testing
- Build: Cmd+B
- Run: Cmd+R (on simulator or device)

To test widgets:
1. Run the main app first to ensure bundle is installed
2. On simulator: Debug > Trigger Widget Reload
3. On device: Add widget manually from Home Screen

## Architecture

### Multi-Language System
**[LanguageManager.swift](Bible Widget/LanguageManager.swift)** provides centralized language management:
- `BibleLanguage` enum - 9 supported languages with localized UI strings, date formats, and file mappings
- `LanguageManager` singleton - Stores user's language preference in App Group UserDefaults
- Automatic widget reload when language changes via `WidgetCenter.shared.reloadAllTimelines()`

### Data Layer
**[BibleVerse.swift](Bible Widget/BibleVerse.swift)** contains all data models and management:
- `BibleData` / `BookInfo` - Codable models matching JSON structure (versioned format with `books` dictionary and `verses` key-value pairs)
- `BibleVerse` - Display model with `reference`, `text`, `bookName`, `bookAbbr`, `bookId`, `chapter`, `verse`
- `BibleVerseManager` singleton - Loads Bible data from language-specific JSON files with in-memory caching
- Curated reference loading from `curated_references.json` (590 verses, ~1.9% selection rate)
- Date-based deterministic verse selection with device-specific randomization
- **Russian Psalm mapping** - Converts Protestant numbering to LXX/Septuagint numbering for Russian Synodal Bible ([BibleVerse.swift:93-122](Bible Widget/BibleVerse.swift#L93))

### Main App
- **[Bible_WidgetApp.swift](Bible Widget/Bible_WidgetApp.swift)** - App entry point
- **[ContentView.swift](Bible Widget/ContentView.swift)** - Full-screen UI with today's verse, date, copy/share buttons, and language selector
- **[LanguageSettingsView.swift](Bible Widget/LanguageSettingsView.swift)** - Language picker sheet showing native name and translation name

### Widget Extension
**[bibleWidgetBundle.swift](bibleWidget/bibleWidgetBundle.swift)** bundles three widget types:
1. `bibleWidget` - Main widget (all home/lock screen sizes)
2. `BibleVerseReferenceWidget` - Lock screen rectangular, reference only
3. `BibleVerseTextWidget` - Lock screen rectangular, text only

**[bibleWidget.swift](bibleWidget/bibleWidget.swift)** implements widget logic:
- `Provider` - TimelineProvider that generates 1-day timeline, updates at midnight
- `bibleWidgetEntryView` - Adaptive UI supporting:
  - Home screen: `.systemSmall`, `.systemMedium`, `.systemLarge`
  - Lock screen: `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`
- Circular lock screen shows book abbreviation for Korean, bookId (e.g., "GEN") for other languages

### Bible Data Files
- **Location**: `Bible Widget/Resources/Bibles/bible_{language_code}.json`
- **Format**: JSON with `version`, `description`, `total_verses`, `books` (dict of bookId → {name, abbr}), `verses` (dict of reference → text)
- **Example reference key**: `"GEN.1.1"` maps to verse text
- **Curated references**: 590 verse references in `curated_references.json`, selected for inspirational content and optimal length (20-220 chars)

## Key Implementation Details

### Verse Selection Algorithm
Device-specific deterministic selection using hash mixing ([BibleVerse.swift:124-189](Bible Widget/BibleVerse.swift#L124)):

1. **Curated reference pool**: Selects from 590 pre-curated references (not full 31,000+ verses)
2. **Device seed**: Random value generated on first launch, stored in App Group UserDefaults
3. **Date-based hashing**: Combines device seed with year, month, and day
4. **Hash mixing**: Uses multiplicative hashing with prime numbers (31, 0x85ebca6b, 0xc2b2ae35) and XOR operations for uniform distribution
5. **Language-specific mapping**: For Russian, applies Psalm number conversion to match LXX numbering
6. **Reference lookup**: Retrieves verse text from language-specific Bible JSON using computed reference key
7. **Result**: Same verse all day across all widgets on same device, but different verses across different devices

```swift
// Simplified algorithm (see BibleVerse.swift for full implementation)
var hash = deviceSeed
hash = hash &* 31 &+ year
hash = hash &* 31 &+ month
hash = hash &* 31 &+ day
// Additional mixing...
let index = abs(hash) % curatedRefs.count
var ref = curatedRefs[index]  // e.g., "GEN.1.1"
if language == .russian { ref = mapRussianPsalmReference(ref) }
let text = bibleData.verses[ref]
```

### Russian Psalm Mapping
The Russian Synodal Bible follows the Septuagint (LXX) numbering system, which differs from Protestant Bibles. The mapping logic ([BibleVerse.swift:93-122](Bible Widget/BibleVerse.swift#L93)) handles:
- Psalms 10 merged into Psalm 9
- Psalms 114-115 merged into Psalm 113
- Psalm 116 split into Psalms 114-115
- Psalm 147 split into Psalms 146-147
- Most other Psalms shifted by -1

### Widget Timeline Management
- Single entry timeline generated per update ([bibleWidget.swift:26-36](bibleWidget/bibleWidget.swift#L26))
- Timeline updates automatically at midnight via `.after(tomorrow)` policy
- Each update calls `BibleVerseManager.getVerseForDate()` for the current date
- Language read from `LanguageManager.shared.currentLanguage`
- WidgetKit handles the midnight refresh automatically

### Shared Code Between Targets
**`BibleVerse.swift`** and **`LanguageManager.swift`** must be included in both targets:
- "Bible Widget" app target
- "bibleWidgetExtension" target

Check target membership in Xcode File Inspector if these managers are not accessible in the widget.

### App Groups for Data Sharing
Both targets use App Group `group.com.taehun.biblewidget` (configured in entitlements):
- Shares device seed via UserDefaults for consistent verse selection
- Shares language preference for consistent display across app and widgets
- Required for widget extension to access shared data
- Ensures same verse and language appear in main app and all widgets on same date

### Widget UI Adaptations
Home screen widgets adapt font sizes and padding based on widget family ([bibleWidget.swift:117-190](bibleWidget/bibleWidget.swift#L117)):
- **Small**: 12pt reference, 14pt text, 6pt padding, 1pt line spacing
- **Medium**: 13pt reference, 15pt text, 10pt padding, 1.5pt line spacing
- **Large**: 15pt reference, 17pt text, 14pt padding, 2pt line spacing
- All sizes support 90% minimum scale factor for long verses
- Center-aligned text for all home screen widgets

### Localization Strategy
No `.strings` files used. All UI text comes from `BibleLanguage` computed properties:
- `todayVerseTitle` - "오늘의 말씀", "Today's Verse", etc.
- `addWidgetPrompt` - Instructions to add widget
- `widgetDisplayName` / `widgetDescription` - Widget configuration text
- `copiedAlertTitle` / `copiedAlertMessage` - Copy confirmation alerts
- `formatDate()` - Language-specific date formatting (e.g., "yyyy년 M월 d일", "MMMM d, yyyy")

## Testing

Tests are currently minimal:
- [Bible_WidgetTests.swift](Bible WidgetTests/Bible_WidgetTests.swift)
- [Bible_WidgetUITests.swift](Bible WidgetUITests/Bible_WidgetUITests.swift)
- [Bible_WidgetUITestsLaunchTests.swift](Bible WidgetUITests/Bible_WidgetUITestsLaunchTests.swift)

To run tests:
- Unit tests: Cmd+U
- UI tests: Select UI test scheme and Cmd+U
