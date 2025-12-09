#!/usr/bin/env python3
"""
Fixed USFX to JSON converter - properly handles all verse containers.
"""
import xml.etree.ElementTree as ET
import json
import re

SKIP_TAGS = {'f', 'x', 'xo', 'xt', 'fr', 'ft', 'fk', 'fq', 'fqa', 'fl', 'fp', 'fv', 'fm', 'ref'}

def get_all_text(elem):
    """Extract all text from element including nested children (but NOT the element's own tail)."""
    parts = []

    if elem.text:
        parts.append(elem.text)

    for child in elem:
        if child.tag in SKIP_TAGS:
            # Skip footnote/xref content but keep tail
            if child.tail:
                parts.append(child.tail)
        else:
            # Recursively get text from child (without its tail)
            parts.append(get_all_text(child))
            # Add the child's tail (text after child's closing tag)
            if child.tail:
                parts.append(child.tail)

    # NOTE: We do NOT include elem.tail here - that's handled by the caller
    return ''.join(parts)

def parse_bible(xml_file):
    """Parse USFX XML file."""
    tree = ET.parse(xml_file)
    root = tree.getroot()

    verses = {}
    books = {}

    # Find all books
    for book_elem in root.findall('.//book'):
        book_id = book_elem.get('id')

        # Extract book metadata
        h_elem = book_elem.find('.//h')
        toc3_elem = book_elem.find('.//toc[@level="3"]')
        toc2_elem = book_elem.find('.//toc[@level="2"]')
        toc1_elem = book_elem.find('.//toc[@level="1"]')

        if h_elem is not None and h_elem.text:
            book_name = h_elem.text.strip()

            # Try toc level 3 first (most languages have this)
            if toc3_elem is not None and toc3_elem.text:
                book_abbr = toc3_elem.text.strip()
            # For Chinese (no level 3), use level 1 as name and level 2 as abbr
            elif toc1_elem is not None and toc1_elem.text and toc2_elem is not None and toc2_elem.text:
                book_name = toc1_elem.text.strip()
                book_abbr = toc2_elem.text.strip()
            else:
                # Fallback
                book_abbr = book_name[:3] if len(book_name) >= 3 else book_name

            books[book_id] = {'name': book_name, 'abbr': book_abbr}

        # Track chapter and verse state
        current_chapter = None
        current_verse = None
        verse_parts = []

        # Track elements to skip (including their descendants)
        skip_elements = set()

        # Iterate through all elements in book
        for elem in book_elem.iter():
            # Skip if this element or any ancestor is in skip list
            if elem in skip_elements:
                continue
            # Chapter marker
            if elem.tag == 'c':
                # Save previous verse if exists before changing chapter
                if current_verse and current_chapter and verse_parts:
                    text = ' '.join(' '.join(verse_parts).split())
                    text = text.replace('¶', '').strip()
                    # Remove space before punctuation
                    text = re.sub(r'\s+([,.:;!?])', r'\1', text)
                    # Fix French apostrophes - handle both ' (U+0027) and ' (U+2019)
                    text = re.sub(r"([a-zA-Z])\s+[\u0027\u2019]", r"\1'", text)
                    if text:  # Only save non-empty verses
                        verses[f"{book_id}.{current_chapter}.{current_verse}"] = text
                    current_verse = None
                    verse_parts = []

                current_chapter = elem.get('id')
                continue

            # Verse start marker
            if elem.tag == 'v':
                # Save previous verse if exists
                if current_verse and current_chapter:
                    text = ' '.join(' '.join(verse_parts).split())
                    text = text.replace('¶', '').strip()
                    # Remove space before punctuation
                    text = re.sub(r'\s+([,.:;!?])', r'\1', text)
                    # Fix French apostrophes - handle both ' (U+0027) and ' (U+2019)
                    text = re.sub(r"([a-zA-Z])\s+[\u0027\u2019]", r"\1'", text)
                    verses[f"{book_id}.{current_chapter}.{current_verse}"] = text

                # Start new verse
                current_verse = elem.get('id')
                verse_parts = []

                # Add tail of <v> tag (text immediately after <v ... />)
                if elem.tail:
                    verse_parts.append(elem.tail)
                continue

            # Verse end marker
            if elem.tag == 've':
                # Save current verse
                if current_verse and current_chapter:
                    text = ' '.join(' '.join(verse_parts).split())
                    text = text.replace('¶', '').strip()
                    # Remove space before punctuation
                    text = re.sub(r'\s+([,.:;!?])', r'\1', text)
                    # Fix French apostrophes - handle both ' (U+0027) and ' (U+2019)
                    text = re.sub(r"([a-zA-Z])\s+[\u0027\u2019]", r"\1'", text)
                    verses[f"{book_id}.{current_chapter}.{current_verse}"] = text

                current_verse = None
                verse_parts = []
                continue

            # Collect text from elements inside verse
            if current_verse and current_chapter:
                # Skip structural tags (but we already handled v and ve above)
                if elem.tag in ['book', 'c', 'h', 'toc', 'li', 'd', 'sp', 'ms', 'mt', 's', 's1', 's2', 's3', 's4', 'b']:
                    # Add all descendants to skip list
                    for desc in elem.iter():
                        skip_elements.add(desc)
                    continue

                # Skip cross-reference paragraphs (style="r")
                if elem.tag == 'p' and elem.get('style') == 'r':
                    # Add all descendants to skip list
                    for desc in elem.iter():
                        skip_elements.add(desc)
                    continue

                # Skip footnotes/cross-refs but keep tail
                if elem.tag in SKIP_TAGS:
                    if elem.tail:
                        verse_parts.append(elem.tail)
                    continue

                # For inline wrappers, get ALL text including children
                # and mark children to skip to avoid double-processing
                # wj = words of Jesus, nd = name of deity, add = added words, tl = transliteration
                if elem.tag in ['wj', 'nd', 'add', 'tl']:
                    # Get all text from this element including nested children
                    text = get_all_text(elem)
                    if text:
                        verse_parts.append(text)
                    # Add tail
                    if elem.tail:
                        verse_parts.append(elem.tail)
                    # Mark all descendants to skip
                    for desc in elem.iter():
                        if desc != elem:  # Don't skip elem itself (already processed)
                            skip_elements.add(desc)
                    continue

                # For poetry/quote tags, just get direct text and let children be processed
                if elem.tag == 'q':
                    if elem.text:
                        verse_parts.append(elem.text)
                    if elem.tail:
                        verse_parts.append(elem.tail)
                    continue

                # Get text from inline elements (w, add, etc.)
                # This includes the element's text AND all nested children
                text = get_all_text(elem)
                if text:
                    verse_parts.append(text)

                # IMPORTANT: Also add the tail (text after closing tag)
                if elem.tail:
                    verse_parts.append(elem.tail)

    return verses, books

def convert(xml_file, json_file, version, desc):
    """Convert USFX to JSON."""
    print(f"\n{xml_file}")

    verses, books = parse_bible(xml_file)

    # Save
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump({
            'version': version,
            'description': desc,
            'total_verses': len(verses),
            'books': books,
            'verses': verses
        }, f, ensure_ascii=False, indent=2)

    # Stats
    empty = sum(1 for v in verses.values() if not v)
    short = sum(1 for v in verses.values() if v and len(v) < 10)
    avg = sum(len(v) for v in verses.values()) / len(verses) if verses else 0

    print(f"  → {json_file}")
    print(f"  📊 {len(verses)} verses, {empty} empty, {short} short, {avg:.1f} avg")

    # Samples
    for ref in ['GEN.1.5', 'GEN.2.2', 'JHN.3.16']:
        if ref in verses:
            text = verses[ref]
            display = text[:70] + '...' if len(text) > 70 else text
            print(f"  📖 {ref}: {display}")

    return len(verses) >= 20000 and empty < 100

# Run
print("="*80)
print("FIXED BIBLE CONVERSION")
print("="*80)

results = []
for xml, out, ver, desc in [
    ('bibles/eng-kjv2006_usfx/eng-kjv2006_usfx.xml', 'bible_en.json', 'KJV', 'King James Version'),
    ('bibles/spaRV1909_usfx/spaRV1909_usfx.xml', 'bible_es.json', 'RVR1909', 'Reina-Valera 1909'),
    ('bibles/porbrbsl_usfx/porbrbsl_usfx.xml', 'bible_pt.json', 'BRBSL', 'Bíblia Portuguesa Mundial'),
    ('bibles/fraLSG_usfx/fraLSG_usfx.xml', 'bible_fr.json', 'LSG', 'Louis Segond 1910'),
    ('bibles/deu1912_usfx/deu1912_usfx.xml', 'bible_de.json', 'LUT1912', 'Luther 1912'),
    ('bibles/russyn_usfx/russyn_usfx.xml', 'bible_ru.json', 'RUSSYNODAL', 'Russian Synodal'),
    ('bibles/cmn-cu89s_usfx/cmn-cu89s_usfx.xml', 'bible_zh_CN.json', 'CUV_S', 'Chinese Union Simplified'),
    ('bibles/cmn-cu89t_usfx/cmn-cu89t_usfx.xml', 'bible_zh_TW.json', 'CUV_T', 'Chinese Union Traditional'),
]:
    success = convert(xml, out, ver, desc)
    results.append((out, success))

print("\n" + "="*80)
print("SUMMARY")
print("="*80)
for name, success in results:
    print(f"{'✅' if success else '❌'} {name}")

successful = sum(1 for _, s in results if s)
print(f"\n{successful}/{len(results)} successful")

if successful == len(results):
    print("\n🎉 All conversions completed successfully!")
