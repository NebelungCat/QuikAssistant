-- Helper: edit Lua files preserving windows-1251 encoding
-- Usage: python file_edit.py <file> <old_text> <new_text>

import sys
import os

def edit_file(filepath, old_text, new_text):
    # Read as bytes
    with open(filepath, 'rb') as f:
        raw = f.read()
    
    # Decode as windows-1251
    try:
        content = raw.decode('cp1251')
    except UnicodeDecodeError:
        # Fallback: try utf-8
        content = raw.decode('utf-8')
        print("WARNING: file was already UTF-8, not windows-1251")
    
    # Perform replacement
    if old_text not in content:
        print(f"ERROR: old_text not found in {filepath}")
        print(f"Looking for: {old_text[:80]}...")
        sys.exit(1)
    
    new_content = content.replace(old_text, new_text, 1)
    
    # Write back as windows-1251
    with open(filepath, 'wb') as f:
        f.write(new_content.encode('cp1251'))
    
    print(f"OK: {filepath} edited ({len(content)} -> {len(new_content)} chars)")

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python file_edit.py <file> <old_text> <new_text>")
        print("For multiline text, use @file syntax: @old.txt @new.txt")
        sys.exit(1)
    
    filepath = sys.argv[1]
    old_text = sys.argv[2]
    new_text = sys.argv[3]
    
    # Support @file syntax for multiline text
    if old_text.startswith('@'):
        with open(old_text[1:], 'r', encoding='cp1251') as f:
            old_text = f.read()
    if new_text.startswith('@'):
        with open(new_text[1:], 'r', encoding='cp1251') as f:
            new_text = f.read()
    
    edit_file(filepath, old_text, new_text)
