//
//  ContentView.swift
//  Bible Widget
//
//  Created by Sirius on 11/7/25.
//

import SwiftUI

struct ContentView: View {
    @State private var todayVerse: BibleVerse

    init() {
        _todayVerse = State(initialValue: BibleVerseManager.shared.getTodayVerse())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 상단 여백
                Spacer()
                    .frame(height: 60)

                // 타이틀
                Text("오늘의 말씀")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.bottom, 8)

                // 날짜
                Text(dateString())
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)

                // 본문 카드
                VStack(alignment: .center, spacing: 16) {
                    // 출처
                    Text(todayVerse.reference)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Divider()

                    // 본문
                    Text(todayVerse.text)
                        .font(.system(size: 18, weight: .regular))
                        .lineSpacing(8)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                )
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)

                // 하단 설명
                VStack(spacing: 8) {
                    Text("위젯을 추가하여")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("매일 새로운 말씀을 받아보세요")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
}

#Preview {
    ContentView()
}
