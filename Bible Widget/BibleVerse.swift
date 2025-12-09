//
//  BibleVerse.swift
//  Bible Widget
//
//  Created by Sirius on 11/7/25.
//

import Foundation
import WidgetKit

// JSON 구조에 맞는 데이터 모델
struct BibleData: Codable {
    let version: String
    let description: String
    let total_verses: Int
    let books: [String: BookInfo]
    let verses: [String: String]  // "GEN.1.1": "text"
}

struct BookInfo: Codable {
    let name: String
    let abbr: String
}

// 표시용 구절 모델
struct BibleVerse {
    let reference: String     // "창세기 1:1" 또는 "Genesis 1:1" (전체 이름)
    let text: String
    let bookName: String      // "창세기" 또는 "Genesis"
    let bookAbbr: String      // "창" 또는 "Gen"
    let bookId: String        // "GEN" (잠금화면 원형 위젯용)
    let chapter: Int
    let verse: Int
}

// 성경 구절 관리 클래스
class BibleVerseManager {
    static let shared = BibleVerseManager()

    private var bibleDataCache: [String: BibleData] = [:]
    private var deviceSeed: Int = 0
    private var curatedRefs: [String] = []

    private init() {
        loadOrCreateDeviceSeed()
        loadCuratedReferences()
    }

    // 디바이스별 고유 시드 생성 또는 로드
    private func loadOrCreateDeviceSeed() {
        let key = "BibleWidget_DeviceSeed"
        let sharedDefaults = UserDefaults(suiteName: "group.com.taehun.biblewidget")

        if let savedSeed = sharedDefaults?.object(forKey: key) as? Int {
            deviceSeed = savedSeed
        } else {
            deviceSeed = Int.random(in: 0...Int.max)
            sharedDefaults?.set(deviceSeed, forKey: key)
        }
    }

    // 큐레이션된 590개 참조 로드
    private func loadCuratedReferences() {
        guard let url = Bundle.main.url(forResource: "curated_references", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let refs = json["references"] as? [String] else {
            return
        }
        self.curatedRefs = refs
    }

    // 특정 언어의 Bible 데이터 로드
    private func loadBibleData(for language: BibleLanguage) -> BibleData? {
        // 캐시 확인
        if let cached = bibleDataCache[language.rawValue] {
            return cached
        }

        // JSON 파일 로드
        guard let url = Bundle.main.url(forResource: language.fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bibleData = try? JSONDecoder().decode(BibleData.self, from: data) else {
            return nil
        }

        // 캐시에 저장
        bibleDataCache[language.rawValue] = bibleData
        return bibleData
    }

    // 러시아어 Psalm 매핑 (LXX 번호 체계로 변환)
    private func mapRussianPsalmReference(_ ref: String) -> String {
        let parts = ref.split(separator: ".")
        guard parts.count == 3, parts[0] == "PSA",
              let psalmNum = Int(parts[1]),
              let verseNum = Int(parts[2]) else {
            return ref
        }

        // Psalm 번호별 매핑 규칙
        switch psalmNum {
        case 1...9, 148...150:
            return ref  // 동일
        case 10:
            return "PSA.9.\(verseNum + 21)"  // Psalm 9에 병합
        case 11...113:
            return "PSA.\(psalmNum - 1).\(verseNum)"  // -1 시프트
        case 114:
            return "PSA.113.\(verseNum)"  // Psalm 113에 병합
        case 115:
            return "PSA.113.\(verseNum + 8)"  // Psalm 113 연장
        case 116:
            return verseNum <= 9 ? "PSA.114.\(verseNum)" : "PSA.115.\(verseNum - 9)"  // 분할
        case 117...146:
            return "PSA.\(psalmNum - 1).\(verseNum)"  // -1 시프트
        case 147:
            return verseNum <= 11 ? "PSA.146.\(verseNum)" : "PSA.147.\(verseNum - 11)"  // 분할
        default:
            return ref
        }
    }

    // 날짜 + 디바이스 기반으로 큐레이션된 구절 선택
    func getVerseForDate(_ date: Date, language: BibleLanguage = .korean) -> BibleVerse {
        guard !curatedRefs.isEmpty else {
            return BibleVerse(
                reference: "오류",
                text: "큐레이션 참조를 불러올 수 없습니다.",
                bookName: "오류",
                bookAbbr: "오류",
                bookId: "ERR",
                chapter: 0,
                verse: 0
            )
        }

        guard let bibleData = loadBibleData(for: language) else {
            return BibleVerse(
                reference: "오류",
                text: "성경 데이터를 불러올 수 없습니다.",
                bookName: "오류",
                bookAbbr: "오류",
                bookId: "ERR",
                chapter: 0,
                verse: 0
            )
        }

        // 날짜를 결정적 해시로 변환
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        var hash = deviceSeed
        hash = hash &* 31 &+ year
        hash = hash &* 31 &+ month
        hash = hash &* 31 &+ day

        // 추가 믹싱으로 균등 분포 개선
        hash = hash ^ (hash >> 16)
        hash = hash &* 0x85ebca6b
        hash = hash ^ (hash >> 13)
        hash = hash &* 0xc2b2ae35
        hash = hash ^ (hash >> 16)

        let index = abs(hash) % curatedRefs.count
        var ref = curatedRefs[index]

        // 러시아어인 경우 Psalm 매핑 적용
        if language == .russian {
            ref = mapRussianPsalmReference(ref)
        }

        // 구절 텍스트 가져오기
        guard let text = bibleData.verses[ref] else {
            return BibleVerse(
                reference: ref,
                text: "구절을 찾을 수 없습니다.",
                bookName: "",
                bookAbbr: "",
                bookId: "",
                chapter: 0,
                verse: 0
            )
        }

        // 참조 파싱 (GEN.1.1)
        let parts = ref.split(separator: ".")
        guard parts.count == 3,
              let chapter = Int(parts[1]),
              let verse = Int(parts[2]) else {
            return BibleVerse(
                reference: ref,
                text: text,
                bookName: "",
                bookAbbr: "",
                bookId: "",
                chapter: 0,
                verse: 0
            )
        }

        let bookId = String(parts[0])
        let bookInfo = bibleData.books[bookId]
        let bookName = bookInfo?.name ?? bookId
        let bookAbbr = bookInfo?.abbr ?? bookId

        // 표시용 참조 생성 (모든 언어 전체 이름 사용)
        let displayRef = "\(bookName) \(chapter):\(verse)"

        return BibleVerse(
            reference: displayRef,
            text: text,
            bookName: bookName,
            bookAbbr: bookAbbr,
            bookId: bookId,  // 잠금화면 원형 위젯용
            chapter: chapter,
            verse: verse
        )
    }

    // 오늘의 구절
    func getTodayVerse(language: BibleLanguage = .korean) -> BibleVerse {
        return getVerseForDate(Date(), language: language)
    }
}
