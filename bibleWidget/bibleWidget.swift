//
//  bibleWidget.swift
//  bibleWidget
//
//  Created by Sirius on 11/7/25.
//

import WidgetKit
import SwiftUI

// Timeline Provider - 위젯 업데이트 시점 관리
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let language = LanguageManager.shared.currentLanguage
        let verse = BibleVerseManager.shared.getTodayVerse(language: language)
        return SimpleEntry(date: Date(), verse: verse, language: language)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let language = LanguageManager.shared.currentLanguage
        let verse = BibleVerseManager.shared.getTodayVerse(language: language)
        let entry = SimpleEntry(date: Date(), verse: verse, language: language)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let language = LanguageManager.shared.currentLanguage

        let verse = BibleVerseManager.shared.getVerseForDate(today, language: language)
        let entry = SimpleEntry(date: today, verse: verse, language: language)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// Timeline Entry - 각 시점의 데이터
struct SimpleEntry: TimelineEntry {
    let date: Date
    let verse: BibleVerse
    let language: BibleLanguage
}

// Widget UI
struct bibleWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            // 잠금화면 원형 위젯
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    // 한국어: 약어 (창), 나머지: bookId (GEN)
                    Text(entry.language == .korean ? entry.verse.bookAbbr : entry.verse.bookId)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text("\(entry.verse.chapter):\(entry.verse.verse)")
                        .font(.system(size: 16, weight: .bold))
                }
            }

        case .accessoryRectangular:
            // 잠금화면 직사각형 위젯
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.verse.reference)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                Text(entry.verse.text)
                    .font(.system(size: 12))
                    .lineLimit(3)
            }
            .widgetAccentable()

        case .accessoryInline:
            // 잠금화면 인라인 위젯 (한 줄)
            HStack(spacing: 4) {
                Text(entry.verse.reference)
                Text("·")
                Text(entry.verse.text)
            }
            .lineLimit(1)

        default:
            // 홈 화면 위젯
            VStack(spacing: 8) {
                Spacer(minLength: 0)

                // 상단: 출처 (가운데 정렬)
                Text(entry.verse.reference)
                    .font(referenceFontForFamily())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                // 중앙: 본문 (가운데 정렬)
                Text(entry.verse.text)
                    .font(textFontForFamily())
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(minimumScaleForFamily())
                    .multilineTextAlignment(.center)
                    .lineSpacing(lineSpacingForFamily())
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, horizontalPadding())
            .padding(.vertical, verticalPadding())
        }
    }

    // 출처 폰트 크기
    private func referenceFontForFamily() -> Font {
        switch family {
        case .systemSmall:
            return .system(size: 12, weight: .medium)
        case .systemMedium:
            return .system(size: 13, weight: .medium)
        case .systemLarge:
            return .system(size: 15, weight: .medium)
        default:
            return .system(size: 13, weight: .medium)
        }
    }

    // 본문 폰트 크기
    private func textFontForFamily() -> Font {
        switch family {
        case .systemSmall:
            return .system(size: 14, weight: .regular)
        case .systemMedium:
            return .system(size: 15, weight: .regular)
        case .systemLarge:
            return .system(size: 17, weight: .regular)
        default:
            return .system(size: 15, weight: .regular)
        }
    }

    // 최소 축소 배율 (긴 텍스트 대응)
    private func minimumScaleForFamily() -> CGFloat {
        return 0.9  // 모든 크기 90%까지 축소
    }

    // 줄 간격
    private func lineSpacingForFamily() -> CGFloat {
        switch family {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 1.5
        case .systemLarge:
            return 2
        default:
            return 1.5
        }
    }

    // 위젯 크기별 수평 패딩
    private func horizontalPadding() -> CGFloat {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 10
        case .systemLarge:
            return 14
        default:
            return 10
        }
    }

    // 위젯 크기별 수직 패딩
    private func verticalPadding() -> CGFloat {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 8
        case .systemLarge:
            return 10
        default:
            return 8
        }
    }
}

// Widget 정의
struct bibleWidget: Widget {
    let kind: String = "bibleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            bibleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LanguageManager.shared.currentLanguage.widgetDisplayName)
        .description(LanguageManager.shared.currentLanguage.widgetDescription)
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,      // 잠금화면 원형
            .accessoryRectangular,   // 잠금화면 직사각형
            .accessoryInline         // 잠금화면 인라인 (한 줄)
        ])
    }
}

// MARK: - 출처만 보여주는 위젯 (잠금화면 직사각형 전용)

struct BibleVerseReferenceWidget: Widget {
    let kind: String = "BibleVerseReferenceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            // 잠금화면 직사각형 - 출처만
            VStack(alignment: .center, spacing: 4) {
                Text(entry.verse.reference)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .widgetAccentable()
        }
        .configurationDisplayName("말씀 출처")
        .description("오늘의 성경 구절 출처")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - 본문만 보여주는 위젯 (잠금화면 직사각형 전용)

struct BibleVerseTextWidget: Widget {
    let kind: String = "BibleVerseTextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            // 잠금화면 직사각형 - 본문만
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.verse.text)
                    .font(.system(size: 12))
                    .lineLimit(4)
            }
            .widgetAccentable()
        }
        .configurationDisplayName("말씀 본문")
        .description("오늘의 성경 구절 본문")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - 프리뷰

#Preview(as: .systemSmall) {
    bibleWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        verse: BibleVerse(
            reference: "요한복음 3:16",
            text: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 저를 믿는 자마다 멸망치 않고 영생을 얻게 하려 하심이니라",
            bookName: "요한복음",
            bookAbbr: "요",
            bookId: "JHN",
            chapter: 3,
            verse: 16
        ),
        language: .korean
    )
}
