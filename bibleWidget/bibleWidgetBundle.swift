//
//  bibleWidgetBundle.swift
//  bibleWidget
//
//  Created by Sirius on 11/7/25.
//

import WidgetKit
import SwiftUI

@main
struct bibleWidgetBundle: WidgetBundle {
    var body: some Widget {
        bibleWidget()
        BibleVerseReferenceWidget()  // 출처만
        BibleVerseTextWidget()        // 본문만
    }
}
