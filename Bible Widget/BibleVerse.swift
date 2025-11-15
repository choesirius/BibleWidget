//
//  BibleVerse.swift
//  Bible Widget
//
//  Created by Sirius on 11/7/25.
//

import Foundation

// JSON 구조에 맞는 데이터 모델
struct BibleData: Codable {
    let version: String
    let description: String
    let total_verses: Int
    let verses: [BibleVerse]
}

struct BibleVerse: Codable {
    let book: String
    let chapter: Int
    let verse: Int
    let reference: String
    let text: String

    // 책 이름 약어 반환
    var bookShort: String {
        return BibleVerse.bookAbbreviations[book] ?? book
    }

    // 성경 66권 약어 매핑
    static let bookAbbreviations: [String: String] = [
        // 구약 (39권)
        "창세기": "창",
        "출애굽기": "출",
        "레위기": "레",
        "민수기": "민",
        "신명기": "신",
        "여호수아": "수",
        "사사기": "삿",
        "룻기": "룻",
        "사무엘상": "삼상",
        "사무엘하": "삼하",
        "열왕기상": "왕상",
        "열왕기하": "왕하",
        "역대상": "대상",
        "역대하": "대하",
        "에스라": "스",
        "느헤미야": "느",
        "에스더": "에",
        "욥기": "욥",
        "시편": "시",
        "잠언": "잠",
        "전도서": "전",
        "아가": "아",
        "이사야": "사",
        "예레미야": "렘",
        "예레미야애가": "애",
        "에스겔": "겔",
        "다니엘": "단",
        "호세아": "호",
        "요엘": "욜",
        "아모스": "암",
        "오바댜": "옵",
        "요나": "욘",
        "미가": "미",
        "나훔": "나",
        "하박국": "합",
        "스바냐": "습",
        "학개": "학",
        "스가랴": "슥",
        "말라기": "말",

        // 신약 (27권)
        "마태복음": "마",
        "마가복음": "막",
        "누가복음": "눅",
        "요한복음": "요",
        "사도행전": "행",
        "로마서": "롬",
        "고린도전서": "고전",
        "고린도후서": "고후",
        "갈라디아서": "갈",
        "에베소서": "엡",
        "빌립보서": "빌",
        "골로새서": "골",
        "데살로니가전서": "살전",
        "데살로니가후서": "살후",
        "디모데전서": "딤전",
        "디모데후서": "딤후",
        "디도서": "딛",
        "빌레몬서": "몬",
        "히브리서": "히",
        "야고보서": "약",
        "베드로전서": "벧전",
        "베드로후서": "벧후",
        "요한일서": "요일",
        "요한이서": "요이",
        "요한삼서": "요삼",
        "유다서": "유",
        "요한계시록": "계"
    ]
}

// 성경 구절 관리 클래스
class BibleVerseManager {
    static let shared = BibleVerseManager()
    private var verses: [BibleVerse] = []
    private var deviceSeed: Int = 0

    private init() {
        loadVerses()
        loadOrCreateDeviceSeed()
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

    // JSON 파일에서 구절 로드
    private func loadVerses() {
        guard let url = Bundle.main.url(forResource: "curated_bible", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bibleData = try? JSONDecoder().decode(BibleData.self, from: data) else {
            return
        }

        self.verses = bibleData.verses
    }

    // 날짜 + 디바이스 기반으로 랜덤 구절 선택 (같은 날은 같은 구절, 디바이스마다 다름)
    func getVerseForDate(_ date: Date) -> BibleVerse {
        guard !verses.isEmpty else {
            return BibleVerse(
                book: "오류",
                chapter: 0,
                verse: 0,
                reference: "오류",
                text: "성경 구절을 불러올 수 없습니다."
            )
        }

        // 날짜를 결정적 해시로 변환 (프로세스 독립적)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        // 간단한 결정적 해시 함수 (큰 소수들 사용)
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

        let index = abs(hash) % verses.count

        return verses[index]
    }

    // 오늘의 구절
    func getTodayVerse() -> BibleVerse {
        return getVerseForDate(Date())
    }
}
