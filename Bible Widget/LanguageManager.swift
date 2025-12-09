//
//  LanguageManager.swift
//  Bible Widget
//
//  Created by Claude on 12/8/24.
//

import Foundation
import WidgetKit

// 지원하는 언어
enum BibleLanguage: String, CaseIterable, Codable {
    case korean = "ko"
    case english = "en"
    case spanish = "es"
    case portuguese = "pt"
    case french = "fr"
    case german = "de"
    case russian = "ru"
    case chineseSimplified = "zh_CN"
    case chineseTraditional = "zh_TW"

    var nativeName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .russian: return "Русский"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        }
    }

    var translationName: String {
        switch self {
        case .korean: return "개역한글"
        case .english: return "King James Version"
        case .spanish: return "Reina-Valera 1909"
        case .portuguese: return "Bíblia Portuguesa Mundial"
        case .french: return "Louis Segond 1910"
        case .german: return "Luther 1912"
        case .russian: return "Russian Synodal"
        case .chineseSimplified: return "和合本"
        case .chineseTraditional: return "和合本"
        }
    }

    var fileName: String {
        return "bible_\(rawValue)"
    }

    // UI 텍스트
    var todayVerseTitle: String {
        switch self {
        case .korean: return "오늘의 말씀"
        case .english: return "Today's Verse"
        case .spanish: return "Verso del Día"
        case .portuguese: return "Versículo do Dia"
        case .french: return "Verset du Jour"
        case .german: return "Vers des Tages"
        case .russian: return "Стих Дня"
        case .chineseSimplified: return "今日经文"
        case .chineseTraditional: return "今日經文"
        }
    }

    var addWidgetPrompt: String {
        switch self {
        case .korean: return "위젯을 추가하여\n매일 새로운 말씀을 받아보세요"
        case .english: return "Add a widget to receive\na new verse every day"
        case .spanish: return "Agrega un widget para recibir\nun nuevo verso cada día"
        case .portuguese: return "Adicione um widget para receber\num novo versículo todos os dias"
        case .french: return "Ajoutez un widget pour recevoir\nun nouveau verset chaque jour"
        case .german: return "Fügen Sie ein Widget hinzu\num täglich einen neuen Vers zu erhalten"
        case .russian: return "Добавьте виджет, чтобы получать\nновый стих каждый день"
        case .chineseSimplified: return "添加小组件\n每天接收新经文"
        case .chineseTraditional: return "新增小工具\n每天接收新經文"
        }
    }

    var widgetDisplayName: String {
        switch self {
        case .korean: return "오늘의 말씀"
        case .english: return "Daily Verse"
        case .spanish: return "Verso Diario"
        case .portuguese: return "Versículo Diário"
        case .french: return "Verset Quotidien"
        case .german: return "Täglicher Vers"
        case .russian: return "Ежедневный Стих"
        case .chineseSimplified: return "每日经文"
        case .chineseTraditional: return "每日經文"
        }
    }

    var widgetDescription: String {
        switch self {
        case .korean: return "매일 새로운 성경 구절을 전해드립니다."
        case .english: return "A new Bible verse every day."
        case .spanish: return "Un nuevo versículo bíblico cada día."
        case .portuguese: return "Um novo versículo bíblico todos os dias."
        case .french: return "Un nouveau verset biblique chaque jour."
        case .german: return "Jeden Tag ein neuer Bibelvers."
        case .russian: return "Новый библейский стих каждый день."
        case .chineseSimplified: return "每天新的圣经经文。"
        case .chineseTraditional: return "每天新的聖經經文。"
        }
    }

    var copiedAlertTitle: String {
        switch self {
        case .korean: return "복사 완료"
        case .english: return "Copied"
        case .spanish: return "Copiado"
        case .portuguese: return "Copiado"
        case .french: return "Copié"
        case .german: return "Kopiert"
        case .russian: return "Скопировано"
        case .chineseSimplified: return "已复制"
        case .chineseTraditional: return "已複製"
        }
    }

    var copiedAlertMessage: String {
        switch self {
        case .korean: return "말씀이 클립보드에 복사되었습니다"
        case .english: return "Verse copied to clipboard"
        case .spanish: return "Versículo copiado al portapapeles"
        case .portuguese: return "Versículo copiado para a área de transferência"
        case .french: return "Verset copié dans le presse-papiers"
        case .german: return "Vers in die Zwischenablage kopiert"
        case .russian: return "Стих скопирован в буфер обмена"
        case .chineseSimplified: return "经文已复制到剪贴板"
        case .chineseTraditional: return "經文已複製到剪貼簿"
        }
    }

    // 날짜 포맷
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)

        switch self {
        case .korean:
            formatter.dateFormat = "yyyy년 M월 d일"
        case .english:
            formatter.dateFormat = "MMMM d, yyyy"
        case .spanish:
            formatter.dateFormat = "d 'de' MMMM 'de' yyyy"
        case .portuguese:
            formatter.dateFormat = "d 'de' MMMM 'de' yyyy"
        case .french:
            formatter.dateFormat = "d MMMM yyyy"
        case .german:
            formatter.dateFormat = "d. MMMM yyyy"
        case .russian:
            formatter.dateFormat = "d MMMM yyyy"
        case .chineseSimplified, .chineseTraditional:
            formatter.dateFormat = "yyyy年M月d日"
        }

        return formatter.string(from: date)
    }

    private var localeIdentifier: String {
        switch self {
        case .korean: return "ko_KR"
        case .english: return "en_US"
        case .spanish: return "es_ES"
        case .portuguese: return "pt_BR"
        case .french: return "fr_FR"
        case .german: return "de_DE"
        case .russian: return "ru_RU"
        case .chineseSimplified: return "zh_CN"
        case .chineseTraditional: return "zh_TW"
        }
    }
}

// 언어 설정 관리 (App Group 공유)
class LanguageManager {
    static let shared = LanguageManager()

    private let key = "BibleWidget_Language"
    private let sharedDefaults = UserDefaults(suiteName: "group.com.taehun.biblewidget")

    private init() {}

    var currentLanguage: BibleLanguage {
        get {
            guard let rawValue = sharedDefaults?.string(forKey: key),
                  let language = BibleLanguage(rawValue: rawValue) else {
                return .korean  // 기본값
            }
            return language
        }
        set {
            sharedDefaults?.set(newValue.rawValue, forKey: key)

            // 위젯 업데이트
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
