#!/usr/bin/env python3
"""
Parse Cambridge and Laban HTML responses to JSON format
"""

import json
import sys
from pathlib import Path
from bs4 import BeautifulSoup


def parse_cambridge(html_content, word):
    """Parse Cambridge Dictionary HTML to JSON"""
    soup = BeautifulSoup(html_content, 'html.parser')
    
    result = {
        "word": word,
        "source": "Cambridge",
        "phonetics": [],
        "meanings": []
    }
    
    # Extract headword
    hw_element = soup.select_one('.hw.dhw')
    if hw_element:
        result["word"] = hw_element.get_text(strip=True)
    
    # Extract phonetics
    ipa_elements = soup.select('.ipa.dipa')
    seen_phonetics = set()
    for el in ipa_elements:
        text = el.get_text(strip=True)
        if text and text not in seen_phonetics:
            seen_phonetics.add(text)
            tag = None
            parent = el.parent
            if parent:
                if parent.select_one('.uk') or 'uk' in parent.get('class', []):
                    tag = 'UK'
                elif parent.select_one('.us') or 'us' in parent.get('class', []):
                    tag = 'US'
            
            phonetic = {"text": text}
            if tag:
                phonetic["tag"] = tag
            result["phonetics"].append(phonetic)
    
    # Extract meanings
    entries = soup.select('.entry-body__el')
    for entry in entries:
        pos_el = entry.select_one('.pos.dpos')
        pos = pos_el.get_text(strip=True) if pos_el else 'General'
        
        def_blocks = entry.select('.def-block.ddef_block')
        definitions = []
        
        for block in def_blocks:
            def_el = block.select_one('.def.ddef_d')
            if not def_el:
                continue
            
            def_text = def_el.get_text(strip=True)
            if def_text.endswith(':'):
                def_text = def_text[:-1].strip()
            
            examples = []
            examp_els = block.select('.examp.dexamp')
            for ex in examp_els:
                examples.append(ex.get_text(strip=True))
            
            if def_text:
                definition = {
                    "definition": def_text,
                    "translations": []
                }
                if examples:
                    definition["example"] = examples[0]
                definitions.append(definition)
        
        if definitions:
            result["meanings"].append({
                "partOfSpeech": pos,
                "definitions": definitions
            })
    
    return result


def parse_laban(html_content, word):
    """Parse Laban Dictionary HTML to JSON"""
    soup = BeautifulSoup(html_content, 'html.parser')
    
    result = {
        "word": word,
        "source": "Laban",
        "phonetics": [],
        "meanings": []
    }
    
    content = soup.select_one('.slide_content')
    if not content:
        return result
    
    children = content.find_all(recursive=False)
    
    current_def_text = ""
    current_examples = []
    
    def flush():
        nonlocal current_def_text, current_examples
        if current_def_text:
            result["meanings"].append({
                "partOfSpeech": "General",
                "definitions": [{
                    "definition": current_def_text,
                    "translations": [],
                    "example": "\n".join(current_examples) if current_examples else None
                }]
            })
        current_def_text = ""
        current_examples = []
    
    for child in children:
        classes = child.get('class', [])
        
        # Check for meaning (green + bold + margin25)
        if 'green' in classes and 'bold' in classes and 'margin25' in classes:
            flush()
            current_def_text = child.get_text(strip=True)
        
        # Check for English example (color-light-blue + margin25)
        elif 'color-light-blue' in classes and 'margin25' in classes:
            current_examples.append(child.get_text(strip=True))
        
        # Check for Vietnamese translation (margin25 but not green/blue)
        elif 'margin25' in classes and 'green' not in classes and 'color-light-blue' not in classes and 'grey' not in classes:
            if current_examples:
                last = current_examples.pop()
                current_examples.append(f"{last} ({child.get_text(strip=True)})")
        
        # Check for POS header (bg-grey + bold)
        elif 'bg-grey' in classes and 'bold' in classes:
            flush()
    
    flush()  # Final flush
    
    return result


def main():
    input_dir = Path("dict-result")
    
    # Parse Cambridge
    cambridge_html = input_dir / "cambridge.json"
    if cambridge_html.exists():
        print("Parsing Cambridge HTML...")
        try:
            with open(cambridge_html, 'r', encoding='utf-8', errors='ignore') as f:
                html_content = f.read()
            
            # Extract word from filename or use default
            word = sys.argv[1] if len(sys.argv) > 1 else "run"
            
            result = parse_cambridge(html_content, word)
            
            output_file = input_dir / "cambridge_parsed.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            print(f"  ✓ Saved to {output_file}")
        except Exception as e:
            print(f"  ✗ Error parsing Cambridge: {e}")
    
    # Parse Laban
    laban_html = input_dir / "laban.json"
    if laban_html.exists():
        print("Parsing Laban HTML...")
        try:
            with open(laban_html, 'r', encoding='utf-8', errors='ignore') as f:
                html_content = f.read()
            
            word = sys.argv[1] if len(sys.argv) > 1 else "run"
            
            result = parse_laban(html_content, word)
            
            output_file = input_dir / "laban_parsed.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            print(f"  ✓ Saved to {output_file}")
        except Exception as e:
            print(f"  ✗ Error parsing Laban: {e}")
    
    print("\nDone! Parsed files:")
    print("  - dict-result/cambridge_parsed.json")
    print("  - dict-result/laban_parsed.json")


if __name__ == "__main__":
    main()

