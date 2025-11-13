# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS Bible Widget application that displays daily Bible verses in Korean. The project consists of:
- Main iOS app ([Bible Widget/](Bible Widget/)) - Displays today's verse in a full-screen UI
- Widget extension ([bibleWidget/](bibleWidget/)) - Provides home screen and lock screen widgets
- Bible verse data ([curated_bible.json](curated_bible.json)) - 1,524 hand-curated Korean Bible verses

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
- Date-based deterministic selection: Same date always returns same verse using `(year * 10000 + month * 100 + day) % verse_count`

### Main App
- **[Bible_WidgetApp.swift](Bible Widget/Bible_WidgetApp.swift)** - App entry point
- **[ContentView.swift](Bible Widget/ContentView.swift)** - Full-screen Korean UI showing today's verse with date and reference

### Widget Extension
**[bibleWidgetBundle.swift](bibleWidget/bibleWidgetBundle.swift)** bundles three widget types:
1. `bibleWidget` - Main widget (all home/lock screen sizes)
2. `BibleVerseReferenceWidget` - Lock screen, reference only
3. `BibleVerseTextWidget` - Lock screen, text only

**[bibleWidget.swift](bibleWidget/bibleWidget.swift)** implements widget logic:
- `Provider` - TimelineProvider that generates 7-day timeline, updates at midnight
- `bibleWidgetEntryView` - Adaptive UI supporting:
  - Home screen: `.systemSmall`, `.systemMedium`, `.systemLarge`
  - Lock screen: `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`

### Bible Data
- **Primary**: `curated_bible.json` - 1,524 verses (개역한글 KRV version)
- **Secondary**: `korean_bible.json` - Full Bible (not currently used)
- JSON structure: `{ version, description, total_verses, verses: [{ book, chapter, verse, reference, text }] }`

## Key Implementation Details

### Verse Selection Algorithm
Date-based deterministic selection ensures:
- Same verse shown across main app and all widgets on same date
- Consistent experience throughout the day
- Predictable behavior for debugging

### Widget Timeline Management
- 7-day timeline pre-generated at midnight
- Updates automatically via `.after(tomorrow)` policy
- Each entry uses `BibleVerseManager.getVerseForDate()` for its specific date

### Shared Code Between Targets
`BibleVerse.swift` must be included in both:
- "Bible Widget" app target
- "bibleWidgetExtension" target

Check target membership in Xcode File Inspector if BibleVerseManager is not accessible.

### Korean Localization
All user-facing strings are hardcoded in Korean:
- Main app: "오늘의 말씀", date format "yyyy년 M월 d일"
- Widget: "오늘의 말씀", "매일 새로운 성경 구절을 전해드립니다"
- No localization files currently used

## Testing

Tests are currently minimal:
- [Bible_WidgetTests.swift](Bible WidgetTests/Bible_WidgetTests.swift)
- [Bible_WidgetUITests.swift](Bible WidgetUITests/Bible_WidgetUITests.swift)
- [Bible_WidgetUITestsLaunchTests.swift](Bible WidgetUITests/Bible_WidgetUITestsLaunchTests.swift)

To run tests:
- Unit tests: Cmd+U
- UI tests: Select UI test scheme and Cmd+U
