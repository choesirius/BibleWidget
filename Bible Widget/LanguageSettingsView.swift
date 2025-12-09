//
//  LanguageSettingsView.swift
//  Bible Widget
//
//  Created by Claude on 12/8/24.
//

import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLanguage: BibleLanguage
    let onLanguageChange: (BibleLanguage) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(BibleLanguage.allCases, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        onLanguageChange(language)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.nativeName)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)

                                Text(language.translationName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if language == selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LanguageSettingsView(
        selectedLanguage: .constant(.korean),
        onLanguageChange: { _ in }
    )
}
