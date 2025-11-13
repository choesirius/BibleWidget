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
        let verse = BibleVerseManager.shared.getTodayVerse()
        return SimpleEntry(date: Date(), verse: verse)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let verse = BibleVerseManager.shared.getTodayVerse()
        let entry = SimpleEntry(date: Date(), verse: verse)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // 오늘 자정부터 7일치 엔트리 생성
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<7 {
            // 각 날짜의 자정
            let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            let verse = BibleVerseManager.shared.getVerseForDate(entryDate)
            let entry = SimpleEntry(date: entryDate, verse: verse)
            entries.append(entry)
        }

        // 다음 자정에 업데이트
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let timeline = Timeline(entries: entries, policy: .after(tomorrow))
        completion(timeline)
    }
}

// Timeline Entry - 각 시점의 데이터
struct SimpleEntry: TimelineEntry {
    let date: Date
    let verse: BibleVerse
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
                    Text(entry.verse.bookShort)
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
            VStack(spacing: 10) {
                Spacer(minLength: 0)

                // 상단: 출처 (가운데 정렬)
                Text(entry.verse.reference)
                    .font(fontForFamily())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                // 중앙: 본문 (가운데 정렬)
                Text(entry.verse.text)
                    .font(fontForFamily())
                    .foregroundStyle(.primary)
                    .lineLimit(lineLimit())
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, horizontalPadding())
            .padding(.vertical, verticalPadding())
        }
    }

    // 위젯 크기별 폰트
    private func fontForFamily() -> Font {
        switch family {
        case .systemSmall:
            return .system(size: 15, weight: .medium, design: .default)
        case .systemMedium:
            return .system(size: 16, weight: .medium, design: .default)
        case .systemLarge:
            return .system(size: 18, weight: .medium, design: .default)
        default:
            return .system(size: 16, weight: .medium, design: .default)
        }
    }

    // 위젯 크기별 최대 라인 수
    private func lineLimit() -> Int {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 4
        case .systemLarge:
            return 12
        default:
            return 6
        }
    }

    // 위젯 크기별 수평 패딩
    private func horizontalPadding() -> CGFloat {
        switch family {
        case .systemSmall:
            return 16
        case .systemMedium:
            return 20
        case .systemLarge:
            return 24
        default:
            return 16
        }
    }

    // 위젯 크기별 수직 패딩
    private func verticalPadding() -> CGFloat {
        switch family {
        case .systemSmall:
            return 16
        case .systemMedium:
            return 18
        case .systemLarge:
            return 20
        default:
            return 16
        }
    }
}

// Widget 정의
struct bibleWidget: Widget {
    let kind: String = "bibleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                bibleWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                bibleWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("오늘의 말씀")
        .description("매일 새로운 성경 구절을 전해드립니다.")
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
            book: "요한복음",
            chapter: 3,
            verse: 16,
            reference: "요한복음 3:16",
            text: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 저를 믿는 자마다 멸망치 않고 영생을 얻게 하려 하심이니라"
        )
    )
}
