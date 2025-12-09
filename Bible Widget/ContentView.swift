//
//  ContentView.swift
//  Bible Widget
//
//  Created by Sirius on 11/7/25.
//

import SwiftUI

struct ContentView: View {
    @State private var todayVerse: BibleVerse
    @State private var showLanguageSettings = false
    @State private var currentLanguage: BibleLanguage
    @State private var showShareSheet = false
    @State private var showCopiedAlert = false

    init() {
        let language = LanguageManager.shared.currentLanguage
        _currentLanguage = State(initialValue: language)
        _todayVerse = State(initialValue: BibleVerseManager.shared.getTodayVerse(language: language))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                // 상단 여백
                Spacer()
                    .frame(height: 60)

                // 타이틀
                Text(currentLanguage.todayVerseTitle)
                    .font(.system(size: 32, weight: .bold))
                    .padding(.bottom, 8)

                // 날짜
                Text(currentLanguage.formatDate(Date()))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)

                // 본문 카드
                VStack(alignment: .center, spacing: 16) {
                    // 출처
                    Text(todayVerse.reference)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, minHeight: 20, alignment: .center)

                    Divider()

                    // 본문
                    Text(todayVerse.text)
                        .font(.system(size: 18, weight: .regular))
                        .lineSpacing(8)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Divider()

                    // 복사 & 공유 버튼
                    HStack(spacing: 32) {
                        Button(action: {
                            copyToClipboard()
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .frame(height: 20)
                        }

                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .frame(height: 20)
                        }
                    }
                    .frame(height: 20)
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
                Text(currentLanguage.addWidgetPrompt)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showLanguageSettings = true
                    }) {
                        Image(systemName: "globe")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView(
                    selectedLanguage: $currentLanguage,
                    onLanguageChange: { newLanguage in
                        LanguageManager.shared.currentLanguage = newLanguage
                        todayVerse = BibleVerseManager.shared.getTodayVerse(language: newLanguage)
                    }
                )
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: [shareText()])
            }
            .alert(currentLanguage.copiedAlertTitle, isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(currentLanguage.copiedAlertMessage)
            }
        }
    }

    // 복사 기능
    private func copyToClipboard() {
        let text = shareText()
        UIPasteboard.general.string = text
        showCopiedAlert = true
    }

    // 공유 텍스트 생성
    private func shareText() -> String {
        let text = todayVerse.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(todayVerse.reference)\n\n\(text)"
    }
}

// 공유 시트
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
