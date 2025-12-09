#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert korean.json to bible_ko.json format
"""

import json

# English abbreviations for verse references (book number -> English abbr)
BOOK_ABBREV_EN = {
    # Old Testament (39 books)
    1: "GEN", 2: "EXO", 3: "LEV", 4: "NUM", 5: "DEU", 6: "JOS", 7: "JDG", 8: "RUT",
    9: "1SA", 10: "2SA", 11: "1KI", 12: "2KI", 13: "1CH", 14: "2CH", 15: "EZR", 16: "NEH",
    17: "EST", 18: "JOB", 19: "PSA", 20: "PRO", 21: "ECC", 22: "SNG", 23: "ISA", 24: "JER",
    25: "LAM", 26: "EZK", 27: "DAN", 28: "HOS", 29: "JOL", 30: "AMO", 31: "OBA", 32: "JON",
    33: "MIC", 34: "NAM", 35: "HAB", 36: "ZEP", 37: "HAG", 38: "ZEC", 39: "MAL",
    # New Testament (27 books)
    40: "MAT", 41: "MRK", 42: "LUK", 43: "JHN", 44: "ACT", 45: "ROM", 46: "1CO", 47: "2CO",
    48: "GAL", 49: "EPH", 50: "PHP", 51: "COL", 52: "1TH", 53: "2TH", 54: "1TI", 55: "2TI",
    56: "TIT", 57: "PHM", 58: "HEB", 59: "JAS", 60: "1PE", 61: "2PE", 62: "1JN", 63: "2JN",
    64: "3JN", 65: "JUD", 66: "REV"
}

# Korean abbreviations for books section (book number -> Korean abbr)
# 구약: 창출레민신수삿룻삼상삼하왕상왕하대상대하스느에욥시잠전아사렘애겔단호욜암옵욘미나합습학슥말
# 신약: 마막눅요행롬고전고후갈엡빌골살전살후딤전딤후딛몬히약벧전벧후요일요이요삼유계
BOOK_ABBREV_KO = {
    # 구약 39권
    1: "창", 2: "출", 3: "레", 4: "민", 5: "신", 6: "수", 7: "삿", 8: "룻",
    9: "삼상", 10: "삼하", 11: "왕상", 12: "왕하", 13: "대상", 14: "대하", 15: "스", 16: "느",
    17: "에", 18: "욥", 19: "시", 20: "잠", 21: "전", 22: "아", 23: "사", 24: "렘",
    25: "애", 26: "겔", 27: "단", 28: "호", 29: "욜", 30: "암", 31: "옵", 32: "욘",
    33: "미", 34: "나", 35: "합", 36: "습", 37: "학", 38: "슥", 39: "말",
    # 신약 27권
    40: "마", 41: "막", 42: "눅", 43: "요", 44: "행", 45: "롬", 46: "고전", 47: "고후",
    48: "갈", 49: "엡", 50: "빌", 51: "골", 52: "살전", 53: "살후", 54: "딤전", 55: "딤후",
    56: "딛", 57: "몬", 58: "히", 59: "약", 60: "벧전", 61: "벧후", 62: "요일", 63: "요이",
    64: "요삼", 65: "유", 66: "계"
}

def convert_korean_bible():
    """Convert korean.json to bible_ko.json format"""

    # Read input
    with open('korean.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Prepare output structure
    output = {
        "version": "Korean",
        "description": "개역성경",
        "total_verses": 0,
        "books": {},
        "verses": {}
    }

    # Process each book
    for book in data['books']:
        book_nr = book['nr']
        book_name = book['name']
        book_abbrev_en = BOOK_ABBREV_EN[book_nr]
        book_abbrev_ko = BOOK_ABBREV_KO[book_nr]

        # Store book info with English key and Korean abbr
        output['books'][book_abbrev_en] = {
            "name": book_name,
            "abbr": book_abbrev_ko
        }

        # Process chapters and verses
        for chapter in book['chapters']:
            chapter_num = chapter['chapter']

            for verse_obj in chapter['verses']:
                verse_num = verse_obj['verse']
                text = verse_obj['text'].strip()

                # Create reference with English abbreviation: GEN.1.1
                ref = f"{book_abbrev_en}.{chapter_num}.{verse_num}"

                output['verses'][ref] = text
                output['total_verses'] += 1

    # Write output
    with open('bible_ko.json', 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"Conversion complete!")
    print(f"Total verses: {output['total_verses']}")
    print(f"Total books: {len(output['books'])}")

if __name__ == '__main__':
    convert_korean_bible()
