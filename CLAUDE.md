# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS Bible Widget application that displays daily Bible verses in Korean. The project consists of:
- Main iOS app ([Bible Widget/](Bible Widget/)) - Displays today's verse in a full-screen UI
- Widget extension ([bibleWidget/](bibleWidget/)) - Provides home screen and lock screen widgets
- Bible verse data ([curated_bible.json](curated_bible.json)) - 1,524 hand-curated Korean Bible verses

**Version**: 1.0.1 (build 2)
**Bundle ID**: `com.taehun.Bible-Widget`
**Widget Extension ID**: `com.taehun.Bible-Widget.bibleWidget`
**Min iOS**: 15.6 (main app), 18.4 (tests)

## ⚖️ CRITICAL: Public Domain Requirement

**This app is intended for commercial use (paid app). ALL Bible translations MUST be in the PUBLIC DOMAIN.**

- ✅ **ALLOWED**: Translations with NO copyright restrictions (public domain, freely reproducible for commercial use)
- ❌ **FORBIDDEN**: Any copyrighted translations requiring licenses, permissions, or royalties
- **Examples of Public Domain translations**:
  - Korean: 개역한글 (KRV), 개역성경
  - English: King James Version (KJV), World English Bible (WEB), American Standard Version (ASV)
  - Other languages: Verify public domain status before adding

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

### Data Layer
**[BibleVerse.swift](Bible Widget/BibleVerse.swift)** contains all data models and management:
- `BibleData` / `BibleVerse` - Codable models matching JSON structure
- `BibleVerseManager` - Singleton that loads verses from `curated_bible.json`
- Date-based deterministic verse selection with device-specific randomization

### Main App
- **[Bible_WidgetApp.swift](Bible Widget/Bible_WidgetApp.swift)** - App entry point
- **[ContentView.swift](Bible Widget/ContentView.swift)** - Full-screen Korean UI showing today's verse with date and reference

### Widget Extension
**[bibleWidgetBundle.swift](bibleWidget/bibleWidgetBundle.swift)** bundles three widget types:
1. `bibleWidget` - Main widget (all home/lock screen sizes)
2. `BibleVerseReferenceWidget` - Lock screen, reference only
3. `BibleVerseTextWidget` - Lock screen, text only

**[bibleWidget.swift](bibleWidget/bibleWidget.swift)** implements widget logic:
- `Provider` - TimelineProvider that generates 1-day timeline, updates at midnight
- `bibleWidgetEntryView` - Adaptive UI supporting:
  - Home screen: `.systemSmall`, `.systemMedium`, `.systemLarge`
  - Lock screen: `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`

### Bible Data
- **Primary**: `curated_bible.json` - 1,524 verses (개역한글 KRV version)
- **Secondary**: `korean_bible.json` - Full Bible (not currently used)
- JSON structure: `{ version, description, total_verses, verses: [{ book, chapter, verse, reference, text }] }`

## Key Implementation Details

### Verse Selection Algorithm
Device-specific deterministic selection using hash mixing ([BibleVerse.swift:140-175](Bible Widget/BibleVerse.swift#L140)):

1. **Device seed**: Random value generated on first launch, stored in App Group UserDefaults
2. **Date-based hashing**: Combines device seed with year, month, and day
3. **Hash mixing**: Uses multiplicative hashing with prime numbers (31, 0x85ebca6b, 0xc2b2ae35) and XOR operations for uniform distribution
4. **Result**: Same verse all day across all widgets on same device, but different verses across different devices
5. **Persistence**: Device seed stored via `group.com.taehun.biblewidget` App Group

```swift
// Simplified algorithm (see BibleVerse.swift for full implementation)
var hash = deviceSeed
hash = hash &* 31 &+ year
hash = hash &* 31 &+ month
hash = hash &* 31 &+ day
// Additional mixing for uniform distribution...
let index = abs(hash) % verses.count
```

### Widget Timeline Management
- Single entry timeline generated per update ([bibleWidget.swift:24-34](bibleWidget/bibleWidget.swift#L24))
- Timeline updates automatically at midnight via `.after(tomorrow)` policy
- Each update calls `BibleVerseManager.getVerseForDate()` for the current date
- WidgetKit handles the midnight refresh automatically

### Shared Code Between Targets
**`BibleVerse.swift`** must be included in both targets:
- "Bible Widget" app target
- "bibleWidgetExtension" target

Check target membership in Xcode File Inspector if BibleVerseManager is not accessible.

### App Groups for Data Sharing
Both targets use App Group `group.com.taehun.biblewidget` (configured in entitlements):
- Shares device seed via UserDefaults for consistent verse selection
- Required for widget extension to access shared data
- Ensures same verse appears in main app and all widgets on same date

### Book Abbreviations
`BibleVerse.bookShort` provides Korean abbreviations for all 66 books (구약 39권 + 신약 27권):
- Used in circular lock screen widget to fit book name in limited space
- Examples: "창세기" → "창", "요한복음" → "요", "고린도전서" → "고전"
- Full mapping in [BibleVerse.swift:31-101](Bible Widget/BibleVerse.swift#L31)

### Korean Localization
All user-facing strings are hardcoded in Korean:
- Main app: "오늘의 말씀", date format "yyyy년 M월 d일"
- Widget: "오늘의 말씀", "매일 새로운 성경 구절을 전해드립니다"
- No localization files currently used

### Widget UI Adaptations
Home screen widgets adapt font sizes and padding based on widget family:
- **Small**: 14pt text, 12pt reference, minimal padding (6pt)
- **Medium**: 15pt text, 13pt reference, moderate padding (10pt)
- **Large**: 17pt text, 15pt reference, larger padding (14pt)
- All sizes support 90% minimum scale factor for long verses

## Testing

Tests are currently minimal:
- [Bible_WidgetTests.swift](Bible WidgetTests/Bible_WidgetTests.swift)
- [Bible_WidgetUITests.swift](Bible WidgetUITests/Bible_WidgetUITests.swift)
- [Bible_WidgetUITestsLaunchTests.swift](Bible WidgetUITests/Bible_WidgetUITestsLaunchTests.swift)

To run tests:
- Unit tests: Cmd+U
- UI tests: Select UI test scheme and Cmd+U
